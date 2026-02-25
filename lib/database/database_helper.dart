import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'eaglet.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate:  _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _seedSyllabus(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS aircraft (
          id          INTEGER PRIMARY KEY,
          tail_number TEXT NOT NULL,
          make_model  TEXT,
          notes       TEXT,
          created_at  TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Recreate aircraft table with UNIQUE constraint
      await db.execute('DROP TABLE IF EXISTS aircraft');
      await db.execute('''
      CREATE TABLE aircraft (
        id          INTEGER PRIMARY KEY,
        tail_number TEXT NOT NULL UNIQUE,
        make_model  TEXT,
        notes       TEXT,
        created_at  TEXT NOT NULL
      )
    ''');
    }
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE instructors (
        id          INTEGER PRIMARY KEY,
        name        TEXT NOT NULL,
        certificate TEXT,
        notes       TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id          INTEGER PRIMARY KEY,
        name        TEXT NOT NULL,
        cert_level  TEXT,
        notes       TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE aircraft (
        id          INTEGER PRIMARY KEY,
        tail_number TEXT NOT NULL,
        make_model  TEXT,
        notes       TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE syllabus_groups (
        id    INTEGER PRIMARY KEY,
        code  TEXT NOT NULL,
        title TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE syllabus_items (
        id       INTEGER PRIMARY KEY,
        group_id INTEGER NOT NULL,
        stage    INTEGER NOT NULL,
        code     TEXT NOT NULL,
        title    TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES syllabus_groups(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE training_sessions (
        id               TEXT PRIMARY KEY,
        student_id       INTEGER NOT NULL,
        instructor_id    INTEGER NOT NULL,
        session_date     TEXT NOT NULL,
        aircraft_id      INTEGER,
        duration_minutes INTEGER,
        notes            TEXT,
        synced           INTEGER DEFAULT 0,
        FOREIGN KEY (student_id)    REFERENCES students(id),
        FOREIGN KEY (instructor_id) REFERENCES instructors(id),
        FOREIGN KEY (aircraft_id)   REFERENCES aircraft(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE student_item_prep (
        id          TEXT PRIMARY KEY,
        student_id  INTEGER NOT NULL,
        item_id     INTEGER NOT NULL,
        read_done   INTEGER DEFAULT 0,
        questions   INTEGER DEFAULT 0,
        instruction INTEGER DEFAULT 0,
        demo        INTEGER DEFAULT 0,
        synced      INTEGER DEFAULT 0,
        UNIQUE(student_id, item_id),
        FOREIGN KEY (student_id) REFERENCES students(id),
        FOREIGN KEY (item_id)    REFERENCES syllabus_items(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE session_items (
        id          TEXT PRIMARY KEY,
        session_id  TEXT NOT NULL,
        item_id     INTEGER NOT NULL,
        level       TEXT NOT NULL,
        notes       TEXT,
        timestamp   TEXT NOT NULL,
        synced      INTEGER DEFAULT 0,
        UNIQUE(session_id, item_id),
        FOREIGN KEY (session_id) REFERENCES training_sessions(id),
        FOREIGN KEY (item_id)    REFERENCES syllabus_items(id)
      )
    ''');
  }

  Future<void> _seedSyllabus(Database db) async {
    final batch = db.batch();
    for (final group in syllabusGroups) {
      batch.insert('syllabus_groups', group);
    }
    for (final item in syllabusItems) {
      batch.insert('syllabus_items', item);
    }
    await batch.commit(noResult: true);
  }
}
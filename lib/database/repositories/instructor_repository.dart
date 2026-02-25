import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../../models/instructor.dart';

class InstructorRepository {
  final _uuid = const Uuid();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Insert a new instructor and return the saved object with its new ID
  Future<Instructor> insert(Instructor instructor) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final toInsert = instructor.copyWith(createdAt: now);
    final id = await db.insert('instructors', toInsert.toMap());

    return toInsert.copyWith(id: id);
  }

  // Fetch all instructors
  Future<List<Instructor>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'instructors',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Instructor.fromMap(m)).toList();
  }

  // Fetch a single instructor by ID
  Future<Instructor?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'instructors',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Instructor.fromMap(maps.first);
  }

  // Update an existing instructor
  Future<Instructor> update(Instructor instructor) async {
    final db = await _db;
    await db.update(
      'instructors',
      instructor.toMap(),
      where: 'id = ?',
      whereArgs: [instructor.id],
    );
    return instructor;
  }

  // Save app setting for current instructor ID
  Future<void> setCurrentInstructor(int instructorId) async {
    final db = await _db;
    await db.insert(
      'app_settings',
      {'key': 'current_instructor_id', 'value': instructorId.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve the current instructor
  Future<Instructor?> getCurrentInstructor() async {
    final db = await _db;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['current_instructor_id'],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final instructorId = int.tryParse(maps.first['value'] as String);
    if (instructorId == null) return null;

    return getById(instructorId);
  }

  // Check whether first-run setup has been completed
  Future<bool> isSetupComplete() async {
    final instructor = await getCurrentInstructor();
    return instructor != null;
  }
}
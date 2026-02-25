import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../../models/training_session.dart';
import '../../models/session_item.dart';

class SessionRepository {
  final _uuid = const Uuid();
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Insert a new session
  Future<TrainingSession> insert(TrainingSession session) async {
    final db = await _db;
    await db.insert('training_sessions', session.toMap());
    return session;
  }

  // Get all sessions for a student, newest first
  Future<List<TrainingSession>> getForStudent(int studentId) async {
    final db   = await _db;
    final maps = await db.query(
      'training_sessions',
      where:     'student_id = ?',
      whereArgs: [studentId],
      orderBy:   'session_date DESC',
    );
    return maps.map((m) => TrainingSession.fromMap(m)).toList();
  }

  // Get a single session by ID
  Future<TrainingSession?> getById(String id) async {
    final db   = await _db;
    final maps = await db.query(
      'training_sessions',
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return TrainingSession.fromMap(maps.first);
  }

  // Get item count for a session
  Future<int> getItemCount(String sessionId) async {
    final db     = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM session_items WHERE session_id = ?',
      [sessionId],
    );
    return result.first['count'] as int;
  }

  // Insert a session item
  Future<SessionItem> insertItem(SessionItem item) async {
    final db      = await _db;
    final toInsert = item.copyWith(id: _uuid.v4());
    await db.insert(
      'session_items',
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return toInsert;
  }

  // Get all items for a session
  Future<List<SessionItem>> getItemsForSession(String sessionId) async {
    final db   = await _db;
    final maps = await db.query(
      'session_items',
      where:     'session_id = ?',
      whereArgs: [sessionId],
      orderBy:   'timestamp ASC',
    );
    return maps.map((m) => SessionItem.fromMap(m)).toList();
  }

  // Get full item history for a student, newest first
  // Used to compute current level and days since practiced
  Future<List<Map<String, dynamic>>> getItemHistoryForStudent(
      int studentId,
      ) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT
        si.item_id,
        si.level,
        si.timestamp
      FROM session_items si
      INNER JOIN training_sessions ts ON si.session_id = ts.id
      WHERE ts.student_id = ?
      ORDER BY si.timestamp DESC
    ''', [studentId]);
  }

  // Get unsynced sessions for upload
  Future<List<TrainingSession>> getUnsynced() async {
    final db   = await _db;
    final maps = await db.query(
      'training_sessions',
      where:     'synced = 0',
      orderBy:   'session_date ASC',
    );
    return maps.map((m) => TrainingSession.fromMap(m)).toList();
  }

  // Mark a session as synced
  Future<void> markSynced(String sessionId) async {
    final db = await _db;
    await db.update(
      'training_sessions',
      {'synced': 1},
      where:     'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Generate JSON payload for a session including its items
  Future<Map<String, dynamic>> toSyncJson(String sessionId) async {
    final session = await getById(sessionId);
    if (session == null) throw Exception('Session not found: $sessionId');
    final items = await getItemsForSession(sessionId);
    return {
      ...session.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  // Update session details (aircraft, duration, notes)
  Future<void> update(TrainingSession session) async {
    final db = await _db;
    await db.update(
      'training_sessions',
      session.toMap(),
      where:     'id = ?',
      whereArgs: [session.id],
    );
  }

// Update an existing session item
  Future<SessionItem> updateItem(SessionItem item) async {
    final db = await _db;
    await db.update(
      'session_items',
      item.toMap(),
      where:     'id = ?',
      whereArgs: [item.id],
    );
    return item;
  }
}
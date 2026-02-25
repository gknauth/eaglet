import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database_helper.dart';
import '../../models/student_item_prep.dart';

class PrepRepository {
  final _uuid = const Uuid();
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Get all prep records for a student
  Future<List<StudentItemPrep>> getForStudent(int studentId) async {
    final db   = await _db;
    final maps = await db.query(
      'student_item_prep',
      where:     'student_id = ?',
      whereArgs: [studentId],
    );
    return maps.map((m) => StudentItemPrep.fromMap(m)).toList();
  }

  // Get prep record for a specific student + item
  Future<StudentItemPrep?> getForStudentItem(
      int studentId,
      int itemId,
      ) async {
    final db   = await _db;
    final maps = await db.query(
      'student_item_prep',
      where:     'student_id = ? AND item_id = ?',
      whereArgs: [studentId, itemId],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return StudentItemPrep.fromMap(maps.first);
  }

  // Insert a new prep record
  Future<StudentItemPrep> insert(StudentItemPrep prep) async {
    final db      = await _db;
    final toInsert = prep.copyWith(id: _uuid.v4());
    await db.insert(
      'student_item_prep',
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return toInsert;
  }

  // Update an existing prep record
  Future<StudentItemPrep> update(StudentItemPrep prep) async {
    final db      = await _db;
    final toUpdate = prep.copyWith(synced: false);
    await db.update(
      'student_item_prep',
      toUpdate.toMap(),
      where:     'id = ?',
      whereArgs: [prep.id],
    );
    return toUpdate;
  }

  // Upsert — insert if not exists, update if it does
  Future<StudentItemPrep> upsert(StudentItemPrep prep) async {
    final existing = await getForStudentItem(prep.studentId, prep.itemId);
    if (existing == null) {
      return insert(prep.copyWith(id: _uuid.v4()));
    } else {
      return update(prep.copyWith(id: existing.id));
    }
  }
}
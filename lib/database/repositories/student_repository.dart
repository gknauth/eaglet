import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/student.dart';

class StudentRepository {

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Insert a new student and return the saved object with its new ID
  Future<Student> insert(Student student) async {
    final db = await _db;
    final toInsert = student.copyWith(
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await db.insert('students', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  // Fetch all students ordered by name
  Future<List<Student>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'students',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  // Fetch a single student by ID
  Future<Student?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  // Update an existing student
  Future<Student> update(Student student) async {
    final db = await _db;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
    return student;
  }

  // Delete a student by ID
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search students by name
  Future<List<Student>> search(String query) async {
    final db = await _db;
    final maps = await db.query(
      'students',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }
}
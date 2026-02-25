import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/aircraft.dart';

class AircraftRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<Aircraft> insert(Aircraft aircraft) async {
    final db = await _db;
    final toInsert = aircraft.copyWith(
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await db.insert('aircraft', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  Future<List<Aircraft>> getAll() async {
    final db   = await _db;
    final maps = await db.query(
      'aircraft',
      orderBy: 'tail_number ASC',
    );
    return maps.map((m) => Aircraft.fromMap(m)).toList();
  }

  Future<Aircraft?> getById(int id) async {
    final db   = await _db;
    final maps = await db.query(
      'aircraft',
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return Aircraft.fromMap(maps.first);
  }

  Future<Aircraft> update(Aircraft aircraft) async {
    final db = await _db;
    await db.update(
      'aircraft',
      aircraft.toMap(),
      where:     'id = ?',
      whereArgs: [aircraft.id],
    );
    return aircraft;
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      'aircraft',
      where:     'id = ?',
      whereArgs: [id],
    );
  }
}
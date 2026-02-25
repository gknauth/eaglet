import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/syllabus_group.dart';
import '../../models/syllabus_item.dart';

class SyllabusRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<SyllabusGroup>> getGroups() async {
    final db   = await _db;
    final maps = await db.query(
      'syllabus_groups',
      orderBy: 'id ASC',
    );
    return maps.map((m) => SyllabusGroup.fromMap(m)).toList();
  }

  Future<List<SyllabusItem>> getItems() async {
    final db   = await _db;
    final maps = await db.query(
      'syllabus_items',
      orderBy: 'id ASC',
    );
    return maps.map((m) => SyllabusItem.fromMap(m)).toList();
  }

  Future<List<SyllabusItem>> getItemsForGroup(int groupId) async {
    final db   = await _db;
    final maps = await db.query(
      'syllabus_items',
      where:     'group_id = ?',
      whereArgs: [groupId],
      orderBy:   'id ASC',
    );
    return maps.map((m) => SyllabusItem.fromMap(m)).toList();
  }

  Future<SyllabusItem?> getItemById(int id) async {
    final db   = await _db;
    final maps = await db.query(
      'syllabus_items',
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return SyllabusItem.fromMap(maps.first);
  }

  Future<List<SyllabusItem>> getItemsByStage(int groupId, int stage) async {
    final db   = await _db;
    final maps = await db.query(
      'syllabus_items',
      where:     'group_id = ? AND stage = ?',
      whereArgs: [groupId, stage],
      orderBy:   'id ASC',
    );
    return maps.map((m) => SyllabusItem.fromMap(m)).toList();
  }
}
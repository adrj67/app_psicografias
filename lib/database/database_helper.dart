import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (!_initialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, AppConstants.databaseName);
      
      bool exists = await File(path).exists();
      
      if (!exists) {
        ByteData data = await rootBundle.load(AppConstants.databaseAssetPath);
        List<int> bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
      }
      
      return await openDatabase(path);
    } catch (e) {
      throw Exception('Error inicializando base de datos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPsicografias({
    int limit = AppConstants.pageSize, 
    int offset = 0
  }) async {
    final db = await database;
    return await db.query(
      'psicografias',
      limit: limit,
      offset: offset,
      orderBy: 'id ASC',
    );
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM psicografias');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> searchPsicografias(
    String query, {
    int limit = AppConstants.pageSize, 
    int offset = 0
  }) async {
    if (query.isEmpty) {
      return getPsicografias(limit: limit, offset: offset);
    }
    
    final db = await database;
    return await db.query(
      'psicografias',
      where: 'mensaje LIKE ?',
      whereArgs: ['%$query%'],
      limit: limit,
      offset: offset,
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, dynamic>?> getPsicografiaById(int id) async {
    final db = await database;
    final results = await db.query(
      'psicografias',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
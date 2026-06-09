import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    // Si ya tenemos la base de datos, la devolvemos
    if (_database != null) {
      debugPrint('📀 Retornando base de datos existente');
      return _database!;
    }
    
    // Inicializar sqflite para Windows (solo una vez)
    if (!_initialized) {
      debugPrint('🔧 Inicializando sqflite para Windows...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
      debugPrint('✅ sqflite inicializado');
    }
    
    // Inicializar la base de datos
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    debugPrint('📀 Inicializando base de datos (solo una vez)...');
    
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, AppConstants.databaseName);
      debugPrint('📀 Ruta: $path');
      
      bool exists = await File(path).exists();
      debugPrint('📀 ¿Existe archivo? $exists');
      
      if (!exists) {
        debugPrint('📀 Copiando base de datos desde assets...');
        ByteData data = await rootBundle.load(AppConstants.databaseAssetPath);
        debugPrint('📀 Asset cargado: ${data.lengthInBytes} bytes');
        List<int> bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        debugPrint('✅ Base de datos copiada');
      } else {
        debugPrint('✅ Base de datos ya existe');
      }
      
      debugPrint('📀 Abriendo base de datos...');
      final db = await openDatabase(path);
      debugPrint('✅ Base de datos abierta');
      
      // Crear tablas de colecciones (si no existen)
      await _createColeccionesTables(db);
      
      return db;
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  Future<void> _createColeccionesTables(Database db) async {
    debugPrint('📀 Verificando tablas de colecciones...');
    
    // Tabla de colecciones
    await db.execute('''
      CREATE TABLE IF NOT EXISTS colecciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        descripcion TEXT,
        fecha_creacion TEXT NOT NULL
      )
    ''');
    
    // Tabla intermedia
    await db.execute('''
      CREATE TABLE IF NOT EXISTS psicografia_coleccion (
        psicografia_id INTEGER,
        coleccion_id INTEGER,
        PRIMARY KEY (psicografia_id, coleccion_id),
        FOREIGN KEY (psicografia_id) REFERENCES psicografias(id) ON DELETE CASCADE,
        FOREIGN KEY (coleccion_id) REFERENCES colecciones(id) ON DELETE CASCADE
      )
    ''');
    
    debugPrint('✅ Tablas de colecciones verificadas');
  }

  // ============================================================
  // MÉTODOS PARA PSICOGRAFÍAS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPsicografias({int limit = 20, int offset = 0}) async {
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

  Future<List<Map<String, dynamic>>> searchPsicografias(String query, {int limit = 20, int offset = 0}) async {
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

  Future<int> updateNotas(int id, String notas) async {
    final db = await database;
    return await db.update(
      'psicografias',
      {'notas': notas},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // MÉTODOS PARA COLECCIONES
  // ============================================================

  Future<List<Coleccion>> getColecciones() async {
    final db = await database;
    final result = await db.query('colecciones', orderBy: 'nombre ASC');
    return result.map((map) => Coleccion.fromMap(map)).toList();
  }

  Future<int> createColeccion(String nombre, {String? descripcion}) async {
    final db = await database;
    return await db.insert('colecciones', {
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Coleccion>> getColeccionesByPsicografiaId(int psicografiaId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.* FROM colecciones c
      INNER JOIN psicografia_coleccion pc ON c.id = pc.coleccion_id
      WHERE pc.psicografia_id = ?
      ORDER BY c.nombre ASC
    ''', [psicografiaId]);
    return result.map((map) => Coleccion.fromMap(map)).toList();
  }

  Future<void> addPsicografiaToColeccion(int psicografiaId, int coleccionId) async {
    final db = await database;
    await db.insert('psicografia_coleccion', {
      'psicografia_id': psicografiaId,
      'coleccion_id': coleccionId,
    });
  }

  Future<void> removePsicografiaFromColeccion(int psicografiaId, int coleccionId) async {
    final db = await database;
    await db.delete(
      'psicografia_coleccion',
      where: 'psicografia_id = ? AND coleccion_id = ?',
      whereArgs: [psicografiaId, coleccionId],
    );
  }

  Future<List<Map<String, dynamic>>> getPsicografiasByColeccion(
    int coleccionId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.* FROM psicografias p
      INNER JOIN psicografia_coleccion pc ON p.id = pc.psicografia_id
      WHERE pc.coleccion_id = ?
      ORDER BY p.id ASC
      LIMIT ? OFFSET ?
    ''', [coleccionId, limit, offset]);
  }
}
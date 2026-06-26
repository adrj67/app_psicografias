//import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  debugPrint('🔧 Inicializando sqflite...');
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  debugPrint('📀 Abriendo base de datos en memoria...');
  Database db = await openDatabase(inMemoryDatabasePath);
  debugPrint('✅ Base de datos abierta');
  
  await db.execute('CREATE TABLE test (id INTEGER)');
  debugPrint('✅ Tabla creada');
  
  await db.close();
  debugPrint('✅ Prueba completada');
}
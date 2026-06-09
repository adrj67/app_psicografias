import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  print('🔧 Inicializando sqflite...');
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('📀 Abriendo base de datos en memoria...');
  Database db = await openDatabase(inMemoryDatabasePath);
  print('✅ Base de datos abierta');
  
  await db.execute('CREATE TABLE test (id INTEGER)');
  print('✅ Tabla creada');
  
  await db.close();
  print('✅ Prueba completada');
}
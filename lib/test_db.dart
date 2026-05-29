import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  // INICIALIZAR SQLITE PARA WINDOWS (CRÍTICO)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Prueba de Base de Datos'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const TestBody(),
      ),
    );
  }
}

class TestBody extends StatefulWidget {
  const TestBody({super.key});

  @override
  State<TestBody> createState() => _TestBodyState();
}

class _TestBodyState extends State<TestBody> {
  String _mensaje = "Iniciando prueba...";
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _probarBD();
  }

  Future<void> _probarBD() async {
    try {
      setState(() {
        _mensaje = "1. Verificando asset de BD...";
      });
      
      final assetData = await rootBundle.load('assets/database/psicografias.db');
      setState(() {
        _mensaje = "2. Asset encontrado! Tamaño: ${assetData.lengthInBytes} bytes";
      });
      
      setState(() {
        _mensaje = "3. Copiando BD a directorio de documentos...";
      });
      
      Directory docsDir = await getApplicationDocumentsDirectory();
      String dbPath = join(docsDir.path, 'psicografias_test.db');
      
      await File(dbPath).writeAsBytes(assetData.buffer.asUint8List());
      
      setState(() {
        _mensaje = "4. BD copiada a: $dbPath";
      });
      
      setState(() {
        _mensaje = "5. Abriendo base de datos...";
      });
      
      Database db = await openDatabase(dbPath);
      
      setState(() {
        _mensaje = "6. Consultando cantidad de registros...";
      });
      
      List<Map> result = await db.rawQuery('SELECT COUNT(*) as total FROM psicografias');
      int total = result.first['total'] as int;
      
      setState(() {
        _mensaje = "7. Total de registros: $total";
      });
      
      setState(() {
        _mensaje = "8. Obteniendo primeros registros...";
      });
      
      List<Map> muestra = await db.rawQuery(
        'SELECT id, mensaje FROM psicografias LIMIT 5'
      );
      
      await db.close();
      
      String preview = "";
      for (var row in muestra) {
        String texto = row['mensaje'] ?? '';
        String resumen = texto.length > 80 ? '${texto.substring(0, 80)}...' : texto;
        preview += "\n• ID ${row['id']}: $resumen";
      }
      
      setState(() {
        _mensaje = "✅ PRUEBA EXITOSA!\n\n"
                   "Total registros: $total\n\n"
                   "Primeros 5 registros:$preview";
        _cargando = false;
      });
      
    } catch (e, stackTrace) {
      String errorMsg = e.toString();
      String trazaMsg = stackTrace.toString();
      if (trazaMsg.length > 500) {
        trazaMsg = trazaMsg.substring(0, 500);
      }
      
      setState(() {
        _mensaje = "❌ ERROR:\n\n$errorMsg\n\n$trazaMsg";
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_cargando)
              const Center(child: CircularProgressIndicator()),
            Text(
              _mensaje,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
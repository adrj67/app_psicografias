import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';

class HistorialLecturasScreen extends StatefulWidget {
  const HistorialLecturasScreen({super.key});

  @override
  State<HistorialLecturasScreen> createState() =>
      _HistorialLecturasScreenState();
}

class _HistorialLecturasScreenState extends State<HistorialLecturasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _historial = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _ordenAscendente = false; // false = más reciente primero

  Map<int, List<Coleccion>> _coleccionesCache = {};

  int _totalLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dbHelper.getHistorialLecturas(
        ordenAscendente: _ordenAscendente,
      );

      // Obtener total de leídas
      final totalLeidas = await _dbHelper.getTotalLeidas();

      // Cargar colecciones para cada psicografía
      final Map<int, List<Coleccion>> cache = {};
      for (var item in data) {
        final id = item['id'] as int;
        final colecciones = await _dbHelper.getColeccionesByPsicografiaId(id);
        cache[id] = colecciones;
      }

      setState(() {
        _historial = data;
        _coleccionesCache = cache;
        _totalLeidas = totalLeidas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar historial: $e';
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String fechaIso) {
    try {
      // Convertir de UTC a local
      final fechaUtc = DateTime.parse(fechaIso);
      final fechaLocal = fechaUtc.toLocal();
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaLocal);

      if (diferencia.inDays == 0) {
        return 'Hoy ${fechaLocal.hour.toString().padLeft(2, '0')}:${fechaLocal.minute.toString().padLeft(2, '0')}';
      } else if (diferencia.inDays == 1) {
        return 'Ayer ${fechaLocal.hour.toString().padLeft(2, '0')}:${fechaLocal.minute.toString().padLeft(2, '0')}';
      } else if (diferencia.inDays < 7) {
        final dias = [
          'Lunes',
          'Martes',
          'Miércoles',
          'Jueves',
          'Viernes',
          'Sábado',
          'Domingo',
        ];
        return '${dias[fechaLocal.weekday - 1]} ${fechaLocal.hour.toString().padLeft(2, '0')}:${fechaLocal.minute.toString().padLeft(2, '0')}';
      } else {
        return '${fechaLocal.day}/${fechaLocal.month}/${fechaLocal.year}';
      }
    } catch (e) {
      return fechaIso;
    }
  }

  String _getResumen(String mensaje) {
    if (mensaje.isEmpty) return '';
    if (mensaje.length <= AppConstants.mensajeResumenLength) return mensaje;
    return '${mensaje.substring(0, AppConstants.mensajeResumenLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Lecturas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  '$_totalLeidas psicografías leídas',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Botón para invertir orden
                IconButton(
                  icon: Icon(
                    _ordenAscendente
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 20,
                  ),
                  tooltip: _ordenAscendente
                      ? 'Más antiguas primero'
                      : 'Más recientes primero',
                  onPressed: () {
                    setState(() {
                      _ordenAscendente = !_ordenAscendente;
                      _isLoading = true;
                    });
                    _cargarHistorial();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarHistorial,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay psicografías leídas',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Lee una psicografía para que aparezca aquí',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _historial.length,
        itemBuilder: (context, index) {
          final item = _historial[index];
          final psicografia = Psicografia.fromMap(item);
          final fechaLectura = item['fecha_lectura'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: psicografia.imagenPrincipal != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        psicografia.imagenPrincipal!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${psicografia.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
              title: Text(
                _getResumen(psicografia.mensaje),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha de lectura
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _formatearFecha(fechaLectura),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  // Colecciones (si tiene)
                  if (_coleccionesCache[psicografia.id]?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: _coleccionesCache[psicografia.id]!.map((col) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? AppConstants.darkSecondary
                                          : AppConstants.lightSecondary)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    (isDark
                                            ? AppConstants.darkSecondary
                                            : AppConstants.lightSecondary)
                                        .withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              col.nombre,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppConstants.darkSecondary
                                    : AppConstants.lightSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalleScreen(psicografiaId: psicografia.id),
                  ),
                ).then((_) {
                  _cargarHistorial();
                });
              },
            ),
          );
        },
      ),
    );
  }
}

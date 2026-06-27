import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';

class NoLeidasScreen extends StatefulWidget {
  const NoLeidasScreen({super.key});

  @override
  State<NoLeidasScreen> createState() => _NoLeidasScreenState();
}

class _NoLeidasScreenState extends State<NoLeidasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Psicografia> _psicografias = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _ordenAscendente = true; // true = ID ascendente (1,2,3...)
  int _totalNoLeidas = 0;

  // Cache de colecciones por psicografía
  Map<int, List<Coleccion>> _coleccionesCache = {};

  @override
  void initState() {
    super.initState();
    _cargarNoLeidas();
  }

  Future<void> _cargarNoLeidas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener IDs de psicografías leídas
      final leidas = await _dbHelper.getIdsLeidas();
      debugPrint('📊 IDs leídos: ${leidas.length}');
      
      // Obtener todas las psicografías
      final todas = await _dbHelper.getPsicografias(
        limit: AppConstants.totalPsicografias, // 1313, 
        offset: 0,
      );
      
      // Filtrar las NO leídas
      final noLeidas = todas
          .where((item) => !leidas.contains(item['id']))
          .map((e) => Psicografia.fromMap(e))
          .toList();
      
      // Ordenar
      if (_ordenAscendente) {
        noLeidas.sort((a, b) => a.id.compareTo(b.id));
      } else {
        noLeidas.sort((a, b) => b.id.compareTo(a.id));
      }
      
      // Cargar colecciones para cada psicografía
      final Map<int, List<Coleccion>> cache = {};
      for (var p in noLeidas) {
        final colecciones = await _dbHelper.getColeccionesByPsicografiaId(p.id);
        cache[p.id] = colecciones;
      }
      
      setState(() {
        _psicografias = noLeidas;
        _coleccionesCache = cache;
        _totalNoLeidas = noLeidas.length;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar psicografías no leídas: $e';
        _isLoading = false;
      });
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
        title: const Text('No Leídas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  '$_totalNoLeidas psicografías pendientes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Botón para invertir orden
                IconButton(
                  icon: Icon(
                    _ordenAscendente ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                  ),
                  tooltip: _ordenAscendente
                      ? 'ID ascendente (menor a mayor)'
                      : 'ID descendente (mayor a menor)',
                  onPressed: () {
                    setState(() {
                      _ordenAscendente = !_ordenAscendente;
                      _isLoading = true;
                    });
                    _cargarNoLeidas();
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
              onPressed: _cargarNoLeidas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_psicografias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              '¡Todas las psicografías están leídas! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay psicografías pendientes',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNoLeidas,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _psicografias.length,
        itemBuilder: (context, index) {
          final p = _psicografias[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: p.imagenPrincipal != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        p.imagenPrincipal!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${p.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
              title: Text(
                _getResumen(p.mensaje),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador "No leída"
                  Row(
                    children: [
                      Icon(
                        Icons.radio_button_unchecked,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No leída',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  // Colecciones (si tiene)
                  if (_coleccionesCache[p.id]?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: _coleccionesCache[p.id]!.map((col) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (isDark ? AppConstants.darkSecondary : AppConstants.lightSecondary)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (isDark ? AppConstants.darkSecondary : AppConstants.lightSecondary)
                                    .withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              col.nombre,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppConstants.darkSecondary : AppConstants.lightSecondary,
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
                    builder: (context) => DetalleScreen(
                      psicografiaId: p.id,
                    ),
                  ),
                ).then((_) {
                  // Recargar al volver del detalle
                  _cargarNoLeidas();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
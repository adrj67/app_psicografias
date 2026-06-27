import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Psicografia> _psicografias = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  // Cache de colecciones por psicografía
  Map<int, List<Coleccion>> _coleccionesCache = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarNotas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarNotas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> data;

      if (_searchQuery.isNotEmpty) {
        data = await _dbHelper.searchPsicografiasByNotas(_searchQuery);
      } else {
        data = await _dbHelper.getPsicografiasConNotas();
      }

      final psicos = data.map((e) => Psicografia.fromMap(e)).toList();

      // Cargar colecciones para cada psicografía
      final Map<int, List<Coleccion>> cache = {};
      for (var p in psicos) {
        final colecciones = await _dbHelper.getColeccionesByPsicografiaId(p.id);
        cache[p.id] = colecciones;
      }

      setState(() {
        _psicografias = psicos;
        _coleccionesCache = cache;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar notas: $e';
        _isLoading = false;
      });
    }
  }

  String _getResumen(String mensaje) {
    if (mensaje.isEmpty) return '';
    if (mensaje.length <= AppConstants.mensajeResumenLength) return mensaje;
    return '${mensaje.substring(0, AppConstants.mensajeResumenLength)}...';
  }

  String _getNotaPreview(String nota) {
    if (nota.isEmpty) return '';
    if (nota.length <= 50) return nota;
    return '${nota.substring(0, 50)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Psicografías con Notas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en notas...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isLoading = true;
                          });
                          _cargarNotas();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isLoading = true;
                });
                _cargarNotas();
              },
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
              onPressed: _cargarNotas,
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
            Icon(Icons.note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No hay notas que coincidan con "$_searchQuery"'
                  : 'No hay psicografías con notas',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              Text(
                'Agrega notas desde el detalle de una psicografía',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotas,
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
                  // Previsualización de la nota
                  Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getNotaPreview(p.notas ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                            fontStyle: FontStyle.italic,
                          ),
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
                  _cargarNotas();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
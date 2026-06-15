import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import 'detalle_screen.dart';

class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Psicografia> _psicografias = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  String _searchQuery = '';
  String? _errorMessage;
  
  List<Coleccion> _colecciones = [];
  int? _coleccionFiltroId;

  int _totalLeidas = 0;
  final int _totalTotal = 1313;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _cargarMasPsicografias();
      }
    }
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Primero cargar colecciones y estadísticas
      final cols = await _dbHelper.getColecciones();
      final leidas = await _dbHelper.getTotalLeidas();
      
      // Luego cargar psicografías
      final data = await _dbHelper.getPsicografias(
        limit: AppConstants.pageSize,
        offset: 0,
      );
      
      final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
      
      setState(() {
        _colecciones = cols;
        _totalLeidas = leidas;
        _psicografias = nuevos;
        _hasMore = nuevos.length == AppConstants.pageSize;
        _currentPage = 1;
        _isLoading = false;
      });
      
      print('✅ Cargadas ${nuevos.length} psicografías');
      print('✅ Cargadas ${cols.length} colecciones');
      print('✅ Leídas: $leidas');
      
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarMasPsicografias() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data;
      
      if (_coleccionFiltroId != null) {
        data = await _dbHelper.getPsicografiasByColeccion(
          _coleccionFiltroId!,
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      } else if (_searchQuery.isNotEmpty) {
        data = await _dbHelper.searchPsicografias(
          _searchQuery,
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      } else {
        data = await _dbHelper.getPsicografias(
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      }
      
      final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
      
      setState(() {
        _psicografias.addAll(nuevos);
        _hasMore = nuevos.length == AppConstants.pageSize;
        _currentPage++;
        _isLoading = false;
      });
      
      print('📊 Cargada página ${_currentPage - 1}, ${nuevos.length} registros, total: ${_psicografias.length}');
      
    } catch (e) {
      print('❌ Error cargando más: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refresh() {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _psicografias = [];
      _searchQuery = '';
      _coleccionFiltroId = null;
      _isLoading = true;
    });
    _cargarDatosIniciales();
  }

  void _limpiarFiltro() {
    setState(() {
      _coleccionFiltroId = null;
      _currentPage = 0;
      _hasMore = true;
      _psicografias = [];
      _searchQuery = '';
      _isLoading = true;
    });
    _cargarDatosIniciales();
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
        title: Text(AppConstants.appTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de tema
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          // Botón de filtro
          PopupMenuButton<int?>(
            icon: Stack(
              children: [
                const Icon(Icons.filter_alt),
                if (_coleccionFiltroId != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onSelected: (value) async {
              setState(() {
                _coleccionFiltroId = value;
                _currentPage = 0;
                _hasMore = true;
                _psicografias = [];
                _searchQuery = '';
                _isLoading = true;
              });
              
              try {
                List<Map<String, dynamic>> data;
                
                if (value != null) {
                  data = await _dbHelper.getPsicografiasByColeccion(
                    value,
                    limit: AppConstants.pageSize,
                    offset: 0,
                  );
                } else {
                  data = await _dbHelper.getPsicografias(
                    limit: AppConstants.pageSize,
                    offset: 0,
                  );
                }
                
                final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
                
                setState(() {
                  _psicografias = nuevos;
                  _hasMore = nuevos.length == AppConstants.pageSize;
                  _currentPage = 1;
                  _isLoading = false;
                });
                
              } catch (e) {
                print('Error en filtro: $e');
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Error al filtrar: $e';
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Todas las psicografías')),
              if (_colecciones.isNotEmpty) const PopupMenuDivider(),
              ..._colecciones.map((c) => PopupMenuItem(value: c.id, child: Text(c.nombre))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppConstants.searchHint,
                prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
              ),
              onChanged: (value) async {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                  _hasMore = true;
                  _psicografias = [];
                  _coleccionFiltroId = null;
                  _isLoading = true;
                });
                
                try {
                  final data = await _dbHelper.searchPsicografias(
                    value,
                    limit: AppConstants.pageSize,
                    offset: 0,
                  );
                  
                  final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
                  
                  setState(() {
                    _psicografias = nuevos;
                    _hasMore = nuevos.length == AppConstants.pageSize;
                    _currentPage = 1;
                    _isLoading = false;
                  });
                  
                } catch (e) {
                  print('Error en búsqueda: $e');
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
            ),
          ),
          
          // Estadísticas
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book, size: 20, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progreso de lectura', style: TextStyle(fontSize: 12)),
                      Text('$_totalLeidas de $_totalTotal leídas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _totalTotal > 0 ? _totalLeidas / _totalTotal : 0,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        strokeWidth: 6,
                      ),
                      Text('${((_totalLeidas / _totalTotal) * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Filtro activo
          if (_coleccionFiltroId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light 
                      ? Colors.white 
                      : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Text('Filtrado por: ${_colecciones.firstWhere((c) => c.id == _coleccionFiltroId).nombre}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _limpiarFiltro,
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Lista
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_errorMessage != null && _psicografias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            ElevatedButton(onPressed: _refresh, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    
    if (_psicografias.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_psicografias.isEmpty) {
      return Center(
        child: Text(_searchQuery.isNotEmpty ? 'No hay resultados para "$_searchQuery"' : AppConstants.noDataMessage),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _psicografias.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _psicografias.length) {
            return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
          }
          
          final p = _psicografias[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: p.imagenPrincipal != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(p.imagenPrincipal!, width: 50, height: 50, fit: BoxFit.cover),
                    )
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text('${p.id}', style: const TextStyle(color: Colors.white)),
                    ),
              title: Text(_getResumen(p.mensaje), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleScreen(psicografiaId: p.id)),
                );
                if (result == true) {
                  // Recargar todo
                  _refresh();
                  // Actualizar estadísticas manualmente
                  final nuevasLeidas = await _dbHelper.getTotalLeidas();
                  setState(() {
                    _totalLeidas = nuevasLeidas;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}
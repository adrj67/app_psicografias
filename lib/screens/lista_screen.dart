import 'package:app_psicografias/screens/notas_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import 'detalle_screen.dart';
import 'historial_lecturas_screen.dart';
import 'no_leidas_screen.dart';
import 'colecciones_screen.dart';

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

  int _totalLeidas = 0;
  final int _totalTotal = AppConstants.totalPsicografias;

  Map<int, bool> _lecturasCache = {};
  bool _busquedaActiva = false;
  
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      final data = await _dbHelper.getPsicografias(
        limit: AppConstants.pageSize,
        offset: 0,
      );
      
      final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();

      final Map<int, bool> lecturas = {};
      for (var p in nuevos) {
        lecturas[p.id] = await _dbHelper.isLeida(p.id);
      }
      
      final cols = await _dbHelper.getColecciones();
      final leidas = await _dbHelper.getTotalLeidas();
      
      setState(() {
        _psicografias = nuevos;
        _lecturasCache = lecturas;
        _colecciones = cols;
        _totalLeidas = leidas;
        _hasMore = nuevos.length == AppConstants.pageSize;
        _currentPage = 1;
        _isLoading = false;
      });
      
    } catch (e) {
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
      final data = await _dbHelper.getPsicografias(
        limit: AppConstants.pageSize,
        offset: _currentPage * AppConstants.pageSize,
      );
      
      final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
      
      final Map<int, bool> nuevasLecturas = {};
      for (var p in nuevos) {
        nuevasLecturas[p.id] = await _dbHelper.isLeida(p.id);
      }
      
      setState(() {
        _psicografias.addAll(nuevos);
        _lecturasCache.addAll(nuevasLecturas);
        _hasMore = nuevos.length == AppConstants.pageSize;
        _currentPage++;
        _isLoading = false;
      });
      
    } catch (e) {
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
      _lecturasCache = {};
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
          // Botón de Notas
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Psicografías con Notas',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotasScreen(),
                ),
              );
              _refresh();
            },
          ),
          // Botón No Leídas
          IconButton(
            icon: const Icon(Icons.radio_button_unchecked),
            tooltip: 'Psicografías No Leídas',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NoLeidasScreen(),
                ),
              );
              _refresh();
            },
          ),
          // Botón Historial
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Lecturas',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialLecturasScreen(),
                ),
              );
              _refresh();
            },
          ),
          // Botón Colecciones
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            tooltip: 'Gestionar Colecciones',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ColeccionesScreen(),
                ),
              );
              _refresh();
            },
          ),
          // Botón tema
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Cambiar modo Claro/Oscuro',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,  // ← AGREGAR ESTA LÍNEA
              decoration: InputDecoration(
                hintText: AppConstants.searchHint,
                prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();  // ← Limpiar el campo visualmente
                            _searchQuery = '';
                            _busquedaActiva = false;
                            _currentPage = 0;
                            _hasMore = true;
                            _psicografias = [];
                            _lecturasCache = {};
                            _isLoading = true;
                          });
                          _cargarDatosIniciales();  // Mostrar todas
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
              onChanged: (value) async {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                  _hasMore = true;
                  _psicografias = [];
                  _isLoading = true;
                  _busquedaActiva = value.isNotEmpty;
                });
                
                try {
                  final data = await _dbHelper.searchPsicografias(
                    value,
                    limit: AppConstants.pageSize,
                    offset: 0,
                  );
                  
                  final nuevos = data.map((e) => Psicografia.fromMap(e)).toList();
                  
                  final Map<int, bool> lecturas = {};
                  for (var p in nuevos) {
                    lecturas[p.id] = await _dbHelper.isLeida(p.id);
                  }
                  
                  setState(() {
                    _psicografias = nuevos;
                    _lecturasCache = lecturas;
                    _hasMore = nuevos.length == AppConstants.pageSize;
                    _currentPage = 1;
                    _isLoading = false;
                  });
                  
                } catch (e) {
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
          final bool estaLeida = _lecturasCache[p.id] ?? false;
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    estaLeida ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: estaLeida ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleScreen(psicografiaId: p.id)),
                );
                
                if (result == true) {
                  // Actualizar cache de lecturas
                  final Map<int, bool> nuevasLecturas = {};
                  for (var psico in _psicografias) {
                    nuevasLecturas[psico.id] = await _dbHelper.isLeida(psico.id);
                  }
                  
                  final nuevasLeidas = await _dbHelper.getTotalLeidas();
                  
                  setState(() {
                    _lecturasCache = nuevasLecturas;
                    _totalLeidas = nuevasLeidas;
                  });
                }
                
                // ✅ RECARGAR CON EL FILTRO ACTUAL (manteniendo búsqueda)
                await _recargarConFiltroActual();
              },
              /* onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleScreen(psicografiaId: p.id)),
                );
                
                if (result == true) {
                  final Map<int, bool> nuevasLecturas = {};
                  for (var psico in _psicografias) {
                    nuevasLecturas[psico.id] = await _dbHelper.isLeida(psico.id);
                  }
                  
                  final nuevasLeidas = await _dbHelper.getTotalLeidas();
                  
                  setState(() {
                    _lecturasCache = nuevasLecturas;
                    _totalLeidas = nuevasLeidas;
                  });
                }
                
                await _cargarDatosIniciales();
              },*/
            ),
          );
        },
      ),
    );
  }
  Future<void> _recargarConFiltroActual() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Map<String, dynamic>> data;
      
      // ✅ Si hay búsqueda activa, aplicar filtro
      if (_searchQuery.isNotEmpty) {
        data = await _dbHelper.searchPsicografias(
          _searchQuery,
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
      
      // Recargar cache de lecturas
      final Map<int, bool> lecturas = {};
      for (var p in nuevos) {
        lecturas[p.id] = await _dbHelper.isLeida(p.id);
      }
      
      setState(() {
        _psicografias = nuevos;
        _lecturasCache = lecturas;
        _hasMore = nuevos.length == AppConstants.pageSize;
        _currentPage = 1;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
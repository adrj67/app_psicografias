import 'package:app_psicografias/widges/error_widget.dart';
import 'package:app_psicografias/widges/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Psicografia> _psicografias = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String _searchQuery = '';
  String? _errorMessage;
  
  List<Coleccion> _colecciones = [];
  int? _coleccionFiltroId;
  
  final ScrollController _scrollController = ScrollController();
  
  // Control para evitar múltiples llamadas
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // Pequeño delay para asegurar que el widget está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
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
      if (!_isLoading && _hasMore && !_isFetching) {
        _loadPsicografias();
      }
    }
  }

  Future<void> _cargarDatosIniciales() async {
    print('🟢 1. Cargando datos iniciales...');
    
    try {
      // Probar conexión directa a la BD
      print('🟢 2. Intentando obtener database...');
      final db = await _dbHelper.database;
      print('🟢 3. Database obtenida correctamente');
      
      // Verificar tablas
      print('🟢 4. Verificando tablas...');
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      print('📋 Tablas encontradas:');
      for (var row in tables) {
        print('   - ${row['name']}');
      }
      
      // Contar registros
      print('🟢 5. Contando registros...');
      final countResult = await db.rawQuery('SELECT COUNT(*) as total FROM psicografias');
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      print('🟢 6. Total de registros: $count');
      
      if (count == 0) {
        print('⚠️ No hay registros en la tabla psicografias');
        setState(() {
          _errorMessage = 'No hay datos en la base de datos';
          _isLoading = false;
        });
        return;
      }
      
      print('🟢 7. Cargando colecciones...');
      await _loadColecciones();
      
      print('🟢 8. Cargando psicografías...');
      await _loadPsicografias();
      
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadColecciones() async {
    try {
      final cols = await _dbHelper.getColecciones();
      if (mounted) {
        setState(() {
          _colecciones = cols;
        });
      }
    } catch (e) {
      print('Error cargando colecciones: $e');
    }
  }

  Future<void> _loadPsicografias() async {
     print('🟢 ENTRANDO A _loadPsicografias');
    // Evitar múltiples llamadas simultáneas
    if (_isFetching) {
      print('⚠️ Ya hay una carga en progreso, ignorando...');
      return;
    }
    
    if (_isLoading) {
      print('⚠️ Ya está cargando, ignorando...');
      return;
    }
    
    print('🟢 _loadPsicografias - página: $_currentPage');
    
    setState(() {
      _isLoading = true;
      _isFetching = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> data;
      
      if (_coleccionFiltroId != null) {
        print('📂 Cargando por colección: $_coleccionFiltroId');
        data = await _dbHelper.getPsicografiasByColeccion(
          _coleccionFiltroId!,
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      } else if (_searchQuery.isNotEmpty) {
        print('🔍 Buscando: $_searchQuery');
        data = await _dbHelper.searchPsicografias(
          _searchQuery,
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      } else {
        print('📋 Cargando todos');
        data = await _dbHelper.getPsicografias(
          limit: AppConstants.pageSize,
          offset: _currentPage * AppConstants.pageSize,
        );
      }
      
      print('✅ Recibidos ${data.length} registros');
      
      final newPsicografias = data.map((e) => Psicografia.fromMap(e)).toList();
      
      setState(() {
        if (_currentPage == 0) {
          _psicografias = newPsicografias;
        } else {
          _psicografias.addAll(newPsicografias);
        }
        
        _hasMore = newPsicografias.length == AppConstants.pageSize;
        _currentPage++;
        _isLoading = false;
        _isFetching = false;
      });
      
      print('📊 Total en memoria: ${_psicografias.length}');
      
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        _errorMessage = AppConstants.errorLoadingMessage;
        _isLoading = false;
        _isFetching = false;
      });
    }
  }

  Future<void> _refresh() async {
    print('🔄 Refrescando...');
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _psicografias = [];
      _searchQuery = '';
      _coleccionFiltroId = null;
      _isLoading = false;
      _isFetching = false;
    });
    await _loadPsicografias();
  }

  void _limpiarFiltroColeccion() {
    print('🧹 Limpiando filtro...');
    setState(() {
      _coleccionFiltroId = null;
      _currentPage = 0;
      _hasMore = true;
      _psicografias = [];
      _searchQuery = '';
      _isLoading = false;
      _isFetching = false;
    });
    _loadPsicografias();
  }

  String _getResumen(String mensaje) {
    if (mensaje.isEmpty) return '';
    if (mensaje.length <= AppConstants.mensajeResumenLength) return mensaje;
    return '${mensaje.substring(0, AppConstants.mensajeResumenLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ BUILD - isLoading: $_isLoading, psicografias: ${_psicografias.length}');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, //primaryColor.withValues(alpha: 0.05),
      appBar: AppBar(
        title: Text(AppConstants.appTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de tema
          //Consumer<ThemeProvider>(
          //  builder: (context, themeProvider, child) {
          //    return IconButton(
              IconButton(
                icon: Icon(
                  // themeProvider.themeMode == ThemeMode.light
                  //     ? Icons.dark_mode
                  //     : themeProvider.themeMode == ThemeMode.dark
                  //         ? Icons.light_mode
                  //         : Icons.brightness_auto,
                  Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.brightness_auto,
                ),
                onPressed: () {
                  //themeProvider.toggleTheme();
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
                tooltip: 'Cambiar tema',
              ),
            //},
          //),
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
            onSelected: (value) {
              setState(() {
                _coleccionFiltroId = value;
                _currentPage = 0;
                _hasMore = true;
                _psicografias = [];
                _searchQuery = '';
                _isLoading = false;
                _isFetching = false;
              });
              _loadPsicografias();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas las psicografías'),
              ),
              if (_colecciones.isNotEmpty) const PopupMenuDivider(),
              ..._colecciones.map((coleccion) => PopupMenuItem(
                value: coleccion.id,
                child: Text(coleccion.nombre),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppConstants.searchHint,
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
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
                  _currentPage = 0;
                  _hasMore = true;
                  _psicografias = [];
                  _coleccionFiltroId = null;
                  _isLoading = false;
                  _isFetching = false;
                });
                _loadPsicografias();
              },
            ),
          ),
          if (_coleccionFiltroId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Filtrado por: ${_colecciones.firstWhere((c) => c.id == _coleccionFiltroId).nombre}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _limpiarFiltroColeccion,
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _psicografias.isEmpty) {
      return ErrorMessageWidget(
        message: _errorMessage!,
        onRetry: _refresh,
      );
    }
    
    if (_psicografias.isEmpty && _isLoading) {
      return const LoadingWidget();
    }
    
    if (_psicografias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No hay resultados para "$_searchQuery"' 
                  : AppConstants.noDataMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _psicografias.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _psicografias.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final psicografia = _psicografias[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleScreen(
                      psicografiaId: psicografia.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
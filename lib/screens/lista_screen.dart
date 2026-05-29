import 'package:app_psicografias/widges/error_widget.dart';
import 'package:app_psicografias/widges/loading_widget.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';

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
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPsicografias();
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
        _loadPsicografias();
      }
    }
  }

  Future<void> _loadPsicografias() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = _searchQuery.isNotEmpty
          ? await _dbHelper.searchPsicografias(
              _searchQuery,
              limit: AppConstants.pageSize,
              offset: _currentPage * AppConstants.pageSize,
            )
          : await _dbHelper.getPsicografias(
              limit: AppConstants.pageSize,
              offset: _currentPage * AppConstants.pageSize,
            );
      
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
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.errorLoadingMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _psicografias = [];
      _searchQuery = '';
    });
    await _loadPsicografias();
  }

  String _getResumen(String mensaje) {
    if (mensaje.isEmpty) return '';
    if (mensaje.length <= AppConstants.mensajeResumenLength) return mensaje;
    return '${mensaje.substring(0, AppConstants.mensajeResumenLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appTitle),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppConstants.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                  _hasMore = true;
                  _psicografias = [];
                });
                _loadPsicografias();
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
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
      return const Center(child: Text(AppConstants.noDataMessage));
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
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
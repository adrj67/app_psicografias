import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';
import 'detalle_screen.dart';

class ColeccionDetalleScreen extends StatefulWidget {
  final Coleccion coleccion;

  const ColeccionDetalleScreen({
    super.key,
    required this.coleccion,
  });

  @override
  State<ColeccionDetalleScreen> createState() => _ColeccionDetalleScreenState();
}

class _ColeccionDetalleScreenState extends State<ColeccionDetalleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Psicografia> _psicografias = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cargarPsicografias();
  }

  Future<void> _cargarPsicografias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener todas las psicografías de esta colección
      final data = await _dbHelper.getPsicografiasByColeccion(
        widget.coleccion.id!,
        limit: 999, // Sin límite para mostrar todas
        offset: 0,
      );

      final psicos = data.map((e) => Psicografia.fromMap(e)).toList();

      // Obtener total
      final total = await _dbHelper.getTotalPsicografiasByColeccion(widget.coleccion.id!);

      setState(() {
        _psicografias = psicos;
        _total = total;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar psicografías: $e';
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
        title: Text(widget.coleccion.nombre),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_total psicografías',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
              onPressed: _cargarPsicografias,
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
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay psicografías en esta colección',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPsicografias,
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
                  _cargarPsicografias();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
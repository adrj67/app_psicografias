import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';

class ColeccionesScreen extends StatefulWidget {
  const ColeccionesScreen({super.key});

  @override
  State<ColeccionesScreen> createState() => _ColeccionesScreenState();
}

class _ColeccionesScreenState extends State<ColeccionesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Coleccion> _colecciones = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarColecciones();
  }

  Future<void> _cargarColecciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cols = await _dbHelper.getColecciones();
      setState(() {
        _colecciones = cols;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar colecciones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _crearColeccion() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Colección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Década del 1970',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Breve descripción de la colección',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryLight,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true && nombreController.text.trim().isNotEmpty) {
      try {
        await _dbHelper.createColeccion(
          nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
        );
        await _cargarColecciones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Colección creada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editarColeccion(Coleccion coleccion) async {
    final nombreController = TextEditingController(text: coleccion.nombre);
    final descripcionController = TextEditingController(text: coleccion.descripcion ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Colección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryLight,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true && nombreController.text.trim().isNotEmpty) {
      try {
        // Nota: Necesitas agregar un método updateColeccion en DatabaseHelper
        // Por ahora, recreamos la colección (borrar y crear)
        await _dbHelper.deleteColeccion(coleccion.id!);
        await _dbHelper.createColeccion(
          nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
        );
        await _cargarColecciones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Colección actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarColeccion(Coleccion coleccion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Colección'),
        content: Text('¿Estás seguro de eliminar "${coleccion.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteColeccion(coleccion.id!);
        await _cargarColecciones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Colección eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Colecciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _crearColeccion,
            tooltip: 'Nueva Colección',
          ),
        ],
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
              onPressed: _cargarColecciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_colecciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay colecciones',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para crear una',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _colecciones.length,
      itemBuilder: (context, index) {
        final coleccion = _colecciones[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.collections_bookmark,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              coleccion.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: coleccion.descripcion != null
                ? Text(
                    coleccion.descripcion!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editarColeccion(coleccion),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _eliminarColeccion(coleccion),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            onTap: () {
              // Cerrar pantalla y pasar el ID de la coleccion
              Navigator.pop(context, coleccion.id);
              // TODO: Ver psicografías de esta colección
              /* ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ver psicografías de "${coleccion.nombre}"'),
                  duration: const Duration(seconds: 1),
                ),
              );*/
            },
          ),
        );
      },
    );
  }
}
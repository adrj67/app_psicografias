import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';

class ColeccionSelector extends StatefulWidget {
  final int psicografiaId;
  final List<Coleccion> coleccionesDisponibles;
  final List<Coleccion> coleccionesSeleccionadas;
  final Function(List<Coleccion>) onChanged;

  const ColeccionSelector({
    super.key,
    required this.psicografiaId,
    required this.coleccionesDisponibles,
    required this.coleccionesSeleccionadas,
    required this.onChanged,
  });

  @override
  State<ColeccionSelector> createState() => _ColeccionSelectorState();
}

class _ColeccionSelectorState extends State<ColeccionSelector> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late List<Coleccion> _seleccionadas;
  bool _isExpanded = false;
  final TextEditingController _nuevaColeccionController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _seleccionadas = List.from(widget.coleccionesSeleccionadas);
  }

  @override
  void dispose() {
    _nuevaColeccionController.dispose();
    super.dispose();
  }

  Future<void> _toggleColeccion(Coleccion coleccion) async {
    final isSelected = _seleccionadas.any((c) => c.id == coleccion.id);
    
    if (isSelected) {
      await _dbHelper.removePsicografiaFromColeccion(widget.psicografiaId, coleccion.id!);
      if (mounted) {
        setState(() {
          _seleccionadas.removeWhere((c) => c.id == coleccion.id);
        });
      }
    } else {
      await _dbHelper.addPsicografiaToColeccion(widget.psicografiaId, coleccion.id!);
      if (mounted) {
        setState(() {
          _seleccionadas.add(coleccion);
        });
      }
    }
    
    if (mounted) {
      widget.onChanged(_seleccionadas);
      // Indicar que hubo cambios en las colecciones
      // Navigator.pop(context, true);
    }
  }

  Future<void> _crearNuevaColeccion() async {
    if (_nuevaColeccionController.text.trim().isEmpty) return;
    
    if (mounted) {
      setState(() => _isCreating = true);
    }
    
    try {
      final id = await _dbHelper.createColeccion(_nuevaColeccionController.text.trim());
      final nuevaColeccion = Coleccion(
        id: id,
        nombre: _nuevaColeccionController.text.trim(),
        fechaCreacion: DateTime.now(),
      );
      
      await _dbHelper.addPsicografiaToColeccion(widget.psicografiaId, id);
      
      if (mounted) {
        setState(() {
          widget.coleccionesDisponibles.add(nuevaColeccion);
          _seleccionadas.add(nuevaColeccion);
          _isExpanded = false;
          _nuevaColeccionController.clear();
          _isCreating = false;
        });
      }
      
      if (mounted) {
        widget.onChanged(_seleccionadas);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Colección creada y asignada'), backgroundColor: Colors.green),
        );
        // Navigator.pop(context, true);  // Indicar que hubo cambios
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Colecciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() => _isExpanded = !_isExpanded);
                }
              },
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
              label: Text(_isExpanded ? 'Ocultar' : 'Administrar'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Mostrar colecciones seleccionadas como chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _seleccionadas.isEmpty
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin colecciones asignadas',
                      style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  )
              ]
              : _seleccionadas.map((coleccion) {
                  return Chip(
                    label: Text(coleccion.nombre),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _toggleColeccion(coleccion),
                  );
                }).toList(),
        ),
        
        if (_isExpanded) ...[
          const Divider(height: 24),
          const Text('Agregar a colección existente:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.coleccionesDisponibles
                .where((c) => !_seleccionadas.any((s) => s.id == c.id))
                .map((coleccion) {
                  return ActionChip(
                    label: Text(coleccion.nombre),
                    onPressed: () => _toggleColeccion(coleccion),
                  );
                }).toList(),
          ),
          if (widget.coleccionesDisponibles.where((c) => !_seleccionadas.any((s) => s.id == c.id)).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Todas las colecciones ya están asignadas',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 16),
          const Text('O crear nueva colección:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nuevaColeccionController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la nueva colección',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isCreating ? null : _crearNuevaColeccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
import 'package:app_psicografias/widges/coleccion_selector.dart';
import 'package:app_psicografias/widges/imagen_blob_widget.dart';
import 'package:app_psicografias/widges/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/psicografia.dart';
import '../models/coleccion.dart';
import '../utils/constants.dart';

class DetalleScreen extends StatefulWidget {
  final int psicografiaId;

  const DetalleScreen({super.key, required this.psicografiaId});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Psicografia? _psicografia;
  bool _isLoading = true;
  String? _errorMessage;

  TextEditingController? _notasController;
  bool _isEditingNotas = false;
  bool _isSaving = false;

  // Variables para colecciones
  List<Coleccion> _coleccionesDisponibles = [];
  List<Coleccion> _coleccionesSeleccionadas = [];

  bool _fueLeida = false;
  bool _estaLeida = false;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  @override
  void dispose() {
    _notasController?.dispose();
    super.dispose();
  }

  Future<void> _loadDetalle() async {
    try {
      final data = await _dbHelper.getPsicografiaById(widget.psicografiaId);
      if (data != null) {
        final psicografia = Psicografia.fromMap(data);

        // Guardar estado de lectura
        final yaLeida = await _dbHelper.isLeida(widget.psicografiaId);
        _estaLeida = yaLeida;

        setState(() {
          _psicografia = psicografia;
          _notasController = TextEditingController(
            text: psicografia.notas ?? '',
          );
          _isLoading = false;
        });

        // Marcar como leída (solo la primera vez)
        if (!yaLeida) {
          await _dbHelper.marcarComoLeida(widget.psicografiaId);
          _estaLeida = true;
          _fueLeida = true;
        }

        await _loadColecciones();
      } else {
        setState(() {
          _errorMessage = 'No se encontró la psicografía';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.errorLoadingMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLectura() async {
    if (_psicografia == null) return;

    final nuevaLeida = !_estaLeida;

    if (nuevaLeida) {
      await _dbHelper.marcarComoLeida(_psicografia!.id);
    } else {
      await _dbHelper.eliminarLectura(_psicografia!.id);
    }

    setState(() {
      _estaLeida = nuevaLeida;
      _fueLeida = true; // Para notificar cambios al volver
    });

    _mostrarSnackBar(
      nuevaLeida ? '✓ Marcada como leída' : 'Marcada como no leída',
      nuevaLeida ? Colors.green : Colors.grey,
    );
  }

  Future<void> _loadColecciones() async {
    if (_psicografia == null) {
      debugPrint('⚠️ _psicografia es null, no se pueden cargar colecciones');
      return;
    }

    try {
      debugPrint(
        '📚 Cargando colecciones para psicografia ID: ${_psicografia!.id}',
      );

      final disponibles = await _dbHelper.getColecciones();
      debugPrint('📚 Colecciones disponibles: ${disponibles.length}');

      final seleccionadas = await _dbHelper.getColeccionesByPsicografiaId(
        _psicografia!.id,
      );
      debugPrint('📚 Colecciones seleccionadas: ${seleccionadas.length}');

      for (var col in seleccionadas) {
        debugPrint('   - ${col.nombre}');
      }

      if (mounted) {
        setState(() {
          _coleccionesDisponibles = disponibles;
          _coleccionesSeleccionadas = seleccionadas;
        });
        debugPrint(
          '✅ State actualizado con ${_coleccionesSeleccionadas.length} colecciones',
        );
      }
    } catch (e) {
      debugPrint('❌ Error cargando colecciones: $e');
    }
  }

  Future<void> _guardarNotas() async {
    if (_psicografia == null || _notasController == null) {
      _mostrarSnackBar('Error: No hay datos para guardar', Colors.red);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final resultado = await _dbHelper.updateNotas(
        _psicografia!.id,
        _notasController!.text,
      );

      if (resultado > 0) {
        setState(() {
          _psicografia = Psicografia(
            id: _psicografia!.id,
            mensaje: _psicografia!.mensaje,
            urlReferencia: _psicografia!.urlReferencia,
            notas: _notasController!.text,
            coleccionId: _psicografia!.coleccionId,
            imagenPrincipal: _psicografia!.imagenPrincipal,
            imagenSecundaria: _psicografia!.imagenSecundaria,
          );
          _isEditingNotas = false;
          _isSaving = false;
        });

        _mostrarSnackBar('✓ Notas guardadas correctamente', Colors.green);
      } else {
        throw Exception('No se pudo actualizar la base de datos');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _mostrarSnackBar('Error al guardar notas: $e', Colors.red);
    }
  }

  void _copiarAlPortapapeles(String texto, String titulo) {
    Clipboard.setData(ClipboardData(text: texto));
    _mostrarSnackBar(
      '✓ $titulo copiado al portapapeles',
      Theme.of(context).primaryColor,
    );
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevenir el pop automático
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Retornar true si fue la primera vez que se leyó
        Navigator.pop(context, _fueLeida);
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const LoadingWidget(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_psicografia == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No se encontró la psicografía')),
      );
    }

    final psicografia = _psicografia!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
        // Botón para toggle de lectura (estilo Chip)
        GestureDetector(
          onTap: _toggleLectura,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _estaLeida 
                  ? (Theme.of(context).brightness == Brightness.light 
                      ? AppConstants.lightSurface
                      : AppConstants.darkSurface)
                  : (Theme.of(context).brightness == Brightness.light 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade500),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _estaLeida 
                    ? (Theme.of(context).brightness == Brightness.light 
                        ? Colors.green.shade300 
                        : Colors.green.shade700)
                    : (Theme.of(context).brightness == Brightness.light 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade700),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _estaLeida ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _estaLeida 
                      ? (Theme.of(context).brightness == Brightness.light 
                          ? Colors.green.shade700 
                          : Colors.green.shade300)
                      : (Theme.of(context).brightness == Brightness.light 
                          ? Colors.grey.shade200 
                          : Colors.grey.shade400),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _estaLeida ? 'Leída' : 'No leída',
                  style: TextStyle(
                    color: _estaLeida 
                        ? (Theme.of(context).brightness == Brightness.light 
                            ? Colors.green.shade700 
                            : Colors.green.shade300)
                        : (Theme.of(context).brightness == Brightness.light 
                            ? Colors.white 
                            : Colors.white),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _estaLeida ? Icons.undo : Icons.check,
                  color: _estaLeida 
                      ? (Theme.of(context).brightness == Brightness.light 
                          ? Colors.green.shade700 
                          : Colors.green.shade300)
                      : (Theme.of(context).brightness == Brightness.light 
                          ? Colors.white 
                          : Colors.white),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(psicografia),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildImagenColumn(psicografia)),
                const SizedBox(width: 16),
                Expanded(flex: 7, child: _buildTextColumn(psicografia)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABECERA: ID y LINK
  // ============================================================
  Widget _buildHeaderRow(Psicografia psicografia) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${psicografia.id}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (psicografia.urlReferencia != null &&
              psicografia.urlReferencia!.isNotEmpty)
            Expanded(
              child: GestureDetector(
                onTap: () => _copiarAlPortapapeles(
                  psicografia.urlReferencia!,
                  'Referencia',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          psicografia.urlReferencia!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy, size: 14, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // COLUMNA IZQUIERDA: IMAGEN
  // ============================================================
  Widget _buildImagenColumn(Psicografia psicografia) {
    final imagenBytes =
        psicografia.imagenSecundaria ?? psicografia.imagenPrincipal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (imagenBytes != null)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.black87,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(imagenBytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              );
            },
            child: ImagenBlobWidget(
              imagenBytes: imagenBytes,
              height: 550, //250
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '👆 Toca para ampliar',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COLUMNA DERECHA: MENSAJE, COLECCIONES, NOTAS
  // ============================================================
  Widget _buildTextColumn(Psicografia psicografia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mensaje
        _buildMensajeWidget(psicografia),
        const SizedBox(height: 16),

        // Selector de Colecciones
        ColeccionSelector(
          key: ValueKey(_coleccionesSeleccionadas.length),
          psicografiaId: psicografia.id,
          coleccionesDisponibles: _coleccionesDisponibles,
          coleccionesSeleccionadas: _coleccionesSeleccionadas,
          onChanged: (nuevasSeleccionadas) {
            setState(() {
              _coleccionesSeleccionadas = nuevasSeleccionadas;
            });
          },
        ),
        const SizedBox(height: 16),

        // Notas
        _buildNotasWidget(psicografia),
      ],
    );
  }

  // ============================================================
  // WIDGET: MENSAJE
  // ============================================================
  Widget _buildMensajeWidget(Psicografia psicografia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mensaje',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildCopiarBoton(
              () => _copiarAlPortapapeles(psicografia.mensaje, 'Mensaje'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: SelectableText(
            psicografia.mensaje,
            style: const TextStyle(fontSize: 18, height: 1.8),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET: NOTAS
  // ============================================================
  Widget _buildNotasWidget(Psicografia psicografia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Notas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (!_isEditingNotas &&
                psicografia.notas != null &&
                psicografia.notas!.isNotEmpty)
              _buildCopiarBoton(
                () => _copiarAlPortapapeles(psicografia.notas!, 'Notas'),
              ),
            if (!_isEditingNotas) _buildEditarBoton(),
            if (_isEditingNotas) ...[
              _buildCancelarBoton(),
              const SizedBox(width: 4),
              _buildGuardarBoton(),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (_isEditingNotas && _notasController != null)
          Column(
            children: [
              TextField(
                controller: _notasController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Escribe tus notas aquí...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.grey.shade800,
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              psicografia.notas == null || psicografia.notas!.isEmpty
                  ? 'Sin notas - Toca "Editar" para agregar notas'
                  : psicografia.notas!,
              style: TextStyle(
                fontSize: 14,
                fontStyle:
                    psicografia.notas == null || psicografia.notas!.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: psicografia.notas == null || psicografia.notas!.isEmpty
                    ? Theme.of(context).brightness == Brightness.light
                          ? Colors.grey
                          : Colors.grey.shade500
                    : Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // Boton de Cancelar Notas
  Widget _buildCancelarBoton() {
    return GestureDetector(
      onTap: () {
        // Restaurar el texto original
        _notasController?.text = _psicografia?.notas ?? '';
        setState(() {
          _isEditingNotas = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              'Cancelar',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTONES
  // ============================================================
  Widget _buildCopiarBoton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy, size: 14, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            Text(
              'Copiar',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditarBoton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingNotas = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Editar',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarBoton() {
    return GestureDetector(
      onTap: _guardarNotas,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.save, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Guardar',
              style: TextStyle(fontSize: 11, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

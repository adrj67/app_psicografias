import 'dart:typed_data';

class Psicografia {
  final int id;
  final String mensaje;
  final String? urlReferencia;
  final String? notas;
  final int? coleccionId;
  final Uint8List? imagenPrincipal;
  final Uint8List? imagenSecundaria;

  Psicografia({
    required this.id,
    required this.mensaje,
    this.urlReferencia,
    this.notas,
    this.coleccionId, // ← Este campo ya no se usa directamente
    this.imagenPrincipal,
    this.imagenSecundaria,
  });

  factory Psicografia.fromMap(Map<String, dynamic> map) {
    return Psicografia(
      id: map['id'],
      mensaje: map['mensaje'] ?? '',
      urlReferencia: map['url_referencia'],
      notas: map['notas'],
      coleccionId: map['coleccion_id'], // Por compatibilidad
      imagenPrincipal: _bytesToUint8List(map['imagen_principal']),
      imagenSecundaria: _bytesToUint8List(map['imagen_secundaria']),
    );
  }

  static Uint8List? _bytesToUint8List(dynamic bytes) {
    if (bytes == null) return null;
    if (bytes is Uint8List) return bytes;
    if (bytes is List<int>) return Uint8List.fromList(bytes);
    return null;
  }
}
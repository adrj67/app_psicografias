class Psicografia {
  final int id;
  final String mensaje;
  final String? urlReferencia;
  final String? notas;
  final int? coleccionId;

  Psicografia({
    required this.id,
    required this.mensaje,
    this.urlReferencia,
    this.notas,
    this.coleccionId,
  });

  factory Psicografia.fromMap(Map<String, dynamic> map) {
    return Psicografia(
      id: map['id'],
      mensaje: map['mensaje'] ?? '',
      urlReferencia: map['url_referencia'],
      notas: map['notas'],
      coleccionId: map['coleccion_id'],
    );
  }
}
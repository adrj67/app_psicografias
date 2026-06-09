class Coleccion {
  final int? id;
  final String nombre;
  final String? descripcion;
  final DateTime fechaCreacion;

  Coleccion({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.fechaCreacion,
  });

  factory Coleccion.fromMap(Map<String, dynamic> map) {
    return Coleccion(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}
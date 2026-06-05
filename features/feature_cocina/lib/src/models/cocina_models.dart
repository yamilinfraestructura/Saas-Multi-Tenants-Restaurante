class CocinaPedido {
  const CocinaPedido({
    required this.id,
    required this.mesaId,
    required this.nombreCliente,
    required this.estado,
    required this.createdAt,
  });

  factory CocinaPedido.fromJson(Map<String, dynamic> json) {
    return CocinaPedido(
      id: json['id'] as String,
      mesaId: json['mesa_id'] as String,
      nombreCliente: json['nombre_cliente'] as String,
      estado: json['estado'] as String,
      createdAt: json['fecha_creacion'] as String? ?? '',
    );
  }

  final String id;
  final String mesaId;
  final String nombreCliente;
  final String estado;
  final String createdAt;

  CocinaPedido copyWith({String? estado}) {
    return CocinaPedido(
      id: id,
      mesaId: mesaId,
      nombreCliente: nombreCliente,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }
}

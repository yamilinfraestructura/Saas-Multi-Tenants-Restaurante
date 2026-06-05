class PosSala {
  const PosSala({
    required this.id,
    required this.nombre,
  });

  factory PosSala.fromJson(Map<String, dynamic> json) {
    return PosSala(
      id: json['id'] as String,
      nombre: json['nombre_sala'] as String,
    );
  }

  final String id;
  final String nombre;
}

class PosMesa {
  const PosMesa({
    required this.id,
    required this.valor,
    required this.estado,
    required this.salaId,
    this.ultimoPedido,
  });

  factory PosMesa.fromJson(Map<String, dynamic> json) {
    return PosMesa(
      id: json['id'] as String,
      valor: json['valor_mesa'] as String,
      estado: json['estado'] as String,
      salaId: json['sala_id'] as String,
      ultimoPedido: json['ultimo_pedido'] as String?,
    );
  }

  final String id;
  final String valor;
  final String estado;
  final String salaId;
  final String? ultimoPedido;
}

class PosPedidoResumen {
  const PosPedidoResumen({
    required this.id,
    required this.mesaId,
    required this.nombreCliente,
    required this.estado,
    required this.cobroPago,
  });

  factory PosPedidoResumen.fromJson(Map<String, dynamic> json) {
    return PosPedidoResumen(
      id: json['id'] as String,
      mesaId: json['mesa_id'] as String,
      nombreCliente: json['nombre_cliente'] as String,
      estado: json['estado'] as String,
      cobroPago: json['cobro_pago'] as String,
    );
  }

  final String id;
  final String mesaId;
  final String nombreCliente;
  final String estado;
  final String cobroPago;
}

class AdminCategoria {
  const AdminCategoria({
    required this.id,
    required this.nombre,
    required this.posicion,
    required this.status,
    required this.tipo,
    this.emoji,
  });

  factory AdminCategoria.fromJson(Map<String, dynamic> json) {
    return AdminCategoria(
      id: json['id'] as String,
      nombre: json['nombre_categoria'] as String,
      posicion: json['posicion'] as int? ?? 0,
      status: json['status'] as String,
      tipo: json['tipo'] as String,
      emoji: json['emoji'] as String?,
    );
  }

  final String id;
  final String nombre;
  final int posicion;
  final String status;
  final String tipo;
  final String? emoji;
}

class AdminProducto {
  const AdminProducto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoriaId,
    required this.estado,
    required this.tipo,
    this.img,
  });

  factory AdminProducto.fromJson(Map<String, dynamic> json) {
    return AdminProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      categoriaId: json['categoria_id'] as String,
      estado: json['estado'] as String,
      tipo: json['tipo'] as String,
      img: json['img'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson(String tenantId) {
    return {
      'tenant_id': tenantId,
      'nombre': nombre,
      'precio': precio,
      'categoria_id': categoriaId,
      'estado': estado,
      'tipo': tipo,
      if (img != null) 'img': img,
    };
  }

  final String id;
  final String nombre;
  final double precio;
  final String categoriaId;
  final String estado;
  final String tipo;
  final String? img;
}

class AdminSala {
  const AdminSala({
    required this.id,
    required this.nombre,
    required this.numeroPosicion,
    required this.estado,
  });

  factory AdminSala.fromJson(Map<String, dynamic> json) {
    return AdminSala(
      id: json['id'] as String,
      nombre: json['nombre_sala'] as String,
      numeroPosicion: json['numero_posicion'] as int? ?? 0,
      estado: json['estado_sala'] as String,
    );
  }

  final String id;
  final String nombre;
  final int numeroPosicion;
  final String estado;
}

class AdminMesa {
  const AdminMesa({
    required this.id,
    required this.valor,
    required this.estado,
    required this.salaId,
  });

  factory AdminMesa.fromJson(Map<String, dynamic> json) {
    return AdminMesa(
      id: json['id'] as String,
      valor: json['valor_mesa'] as String,
      estado: json['estado'] as String,
      salaId: json['sala_id'] as String,
    );
  }

  final String id;
  final String valor;
  final String estado;
  final String salaId;
}

class AdminUsuario {
  const AdminUsuario({
    required this.id,
    required this.userName,
    required this.email,
    required this.activo,
  });

  factory AdminUsuario.fromJson(Map<String, dynamic> json) {
    return AdminUsuario(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      email: json['email'] as String,
      activo: json['activo'] as bool? ?? true,
    );
  }

  final String id;
  final String userName;
  final String email;
  final bool activo;
}

class TenantPublic {
  const TenantPublic({
    required this.id,
    required this.nombre,
    this.logoUrl,
    required this.estado,
  });

  factory TenantPublic.fromJson(Map<String, dynamic> json) {
    return TenantPublic(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      logoUrl: json['logo_url'] as String?,
      estado: json['estado'] as String,
    );
  }

  final String id;
  final String nombre;
  final String? logoUrl;
  final String estado;

  bool get isAvailable => estado == 'activo';
}

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.posicion,
    this.emoji,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre_categoria'] as String,
      posicion: json['posicion'] as int? ?? 0,
      emoji: json['emoji'] as String?,
    );
  }

  final String id;
  final String nombre;
  final int posicion;
  final String? emoji;
}

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoriaId,
    this.img,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      categoriaId: json['categoria_id'] as String,
      img: json['img'] as String?,
    );
  }

  final String id;
  final String nombre;
  final double precio;
  final String categoriaId;
  final String? img;
}

class PublicMenuData {
  const PublicMenuData({
    required this.tenant,
    required this.categorias,
    required this.productos,
  });

  factory PublicMenuData.fromJson(Map<String, dynamic> json) {
    final categoriasJson = json['categorias'] as List<dynamic>? ?? [];
    final productosJson = json['productos'] as List<dynamic>? ?? [];

    return PublicMenuData(
      tenant: TenantPublic.fromJson(json['tenant'] as Map<String, dynamic>),
      categorias: categoriasJson
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList(),
      productos: productosJson
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final TenantPublic tenant;
  final List<Categoria> categorias;
  final List<Producto> productos;
}

class CartItem {
  const CartItem({
    required this.producto,
    this.cantidad = 1,
  });

  CartItem copyWith({int? cantidad}) {
    return CartItem(
      producto: producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  final Producto producto;
  final int cantidad;

  double get subtotal => producto.precio * cantidad;
}

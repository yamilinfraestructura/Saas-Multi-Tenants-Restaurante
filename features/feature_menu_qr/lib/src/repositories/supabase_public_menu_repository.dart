import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_models.dart';
import 'public_menu_repository.dart';

class SupabasePublicMenuRepository implements PublicMenuRepository {
  SupabasePublicMenuRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PublicMenuData> getMenuBySlug(String slug) async {
    final response = await _client.rpc(
      'get_public_menu',
      params: {'p_slug': slug},
    );

    if (response == null) {
      throw Exception('Menú no disponible');
    }

    final data = Map<String, dynamic>.from(response as Map);
    if (data['error'] != null) {
      throw Exception('Servicio temporalmente no disponible');
    }

    return PublicMenuData.fromJson(data);
  }

  @override
  Future<void> createPedido({
    required String tenantId,
    required String mesaId,
    required String nombreCliente,
    required List<CartItem> items,
  }) async {
    final itemsPayload = items
        .map(
          (item) => {
            'producto_id': item.producto.id,
            'cantidad': item.cantidad,
            'precio_unitario': item.producto.precio,
          },
        )
        .toList();

    await _client.rpc(
      'create_public_pedido',
      params: {
        'p_tenant_id': tenantId,
        'p_mesa_id': mesaId,
        'p_nombre_cliente': nombreCliente,
        'p_items': itemsPayload,
      },
    );
  }
}

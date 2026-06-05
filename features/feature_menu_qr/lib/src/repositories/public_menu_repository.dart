import '../models/menu_models.dart';

abstract class PublicMenuRepository {
  Future<PublicMenuData> getMenuBySlug(String slug);

  Future<void> createPedido({
    required String tenantId,
    required String mesaId,
    required String nombreCliente,
    required List<CartItem> items,
  });
}

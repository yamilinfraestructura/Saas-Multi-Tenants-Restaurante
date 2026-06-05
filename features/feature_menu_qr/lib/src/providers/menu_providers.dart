import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_models.dart';
import '../repositories/public_menu_repository.dart';

final publicMenuRepositoryProvider = Provider<PublicMenuRepository>((ref) {
  return locator<PublicMenuRepository>();
});

final publicMenuProvider =
    FutureProvider.family<PublicMenuData, String>((ref, slug) async {
  final repository = ref.watch(publicMenuRepositoryProvider);
  return repository.getMenuBySlug(slug);
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Producto producto) {
    final index = state.indexWhere((item) => item.producto.id == producto.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(
        cantidad: updated[index].cantidad + 1,
      );
      state = updated;
    } else {
      state = [...state, CartItem(producto: producto)];
    }
  }

  void removeProduct(String productoId) {
    state = state.where((item) => item.producto.id != productoId).toList();
  }

  void updateQuantity(String productoId, int cantidad) {
    if (cantidad <= 0) {
      removeProduct(productoId);
      return;
    }
    state = [
      for (final item in state)
        if (item.producto.id == productoId)
          item.copyWith(cantidad: cantidad)
        else
          item,
    ];
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.cantidad);
});

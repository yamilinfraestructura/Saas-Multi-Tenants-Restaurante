import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return locator<AdminRepository>();
});

final categoriasListProvider = FutureProvider<List<AdminCategoria>>((ref) async {
  return ref.watch(adminRepositoryProvider).getCategorias();
});

final productosListProvider =
    FutureProvider.family<List<AdminProducto>, String?>((ref, categoriaId) async {
  return ref.watch(adminRepositoryProvider).getProductos(categoriaId: categoriaId);
});

final salasListProvider = FutureProvider<List<AdminSala>>((ref) async {
  return ref.watch(adminRepositoryProvider).getSalas();
});

final mesasListProvider =
    FutureProvider.family<List<AdminMesa>, String?>((ref, salaId) async {
  return ref.watch(adminRepositoryProvider).getMesas(salaId: salaId);
});

final usuariosListProvider = FutureProvider<List<AdminUsuario>>((ref) async {
  return ref.watch(adminRepositoryProvider).getUsuarios();
});

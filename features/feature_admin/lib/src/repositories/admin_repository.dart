import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<List<AdminCategoria>> getCategorias();
  Future<List<AdminProducto>> getProductos({String? categoriaId});
  Future<AdminProducto> createProducto(AdminProducto producto);
  Future<void> deleteProducto(String id);

  Future<List<AdminSala>> getSalas();
  Future<List<AdminMesa>> getMesas({String? salaId});
  Future<AdminSala> createSala(String nombre);
  Future<AdminMesa> createMesa({required String salaId, required String valor});

  Future<List<AdminUsuario>> getUsuarios();
}

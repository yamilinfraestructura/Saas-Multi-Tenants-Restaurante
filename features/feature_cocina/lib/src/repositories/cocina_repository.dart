import '../models/cocina_models.dart';

abstract class CocinaRepository {
  Stream<List<CocinaPedido>> watchPedidosActivos();
  Future<void> updateEstado(String pedidoId, String nuevoEstado);
}

import '../models/pos_models.dart';

abstract class PosRepository {
  Future<List<PosSala>> getSalas();
  Future<List<PosMesa>> getMesas({String? salaId});
  Future<List<PosPedidoResumen>> getPedidosActivosMesa(String mesaId);
  Future<void> liberarMesa(String mesaId);
}

import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pos_models.dart';
import '../repositories/pos_repository.dart';
import '../services/thermal_printer_service.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return locator<PosRepository>();
});

final thermalPrinterProvider = Provider<ThermalPrinterService>((ref) {
  return locator<ThermalPrinterService>();
});

final posSalasProvider = FutureProvider<List<PosSala>>((ref) async {
  return ref.watch(posRepositoryProvider).getSalas();
});

final posMesasProvider =
    FutureProvider.family<List<PosMesa>, String?>((ref, salaId) async {
  return ref.watch(posRepositoryProvider).getMesas(salaId: salaId);
});

final mesaPedidosProvider =
    FutureProvider.family<List<PosPedidoResumen>, String>((ref, mesaId) async {
  return ref.watch(posRepositoryProvider).getPedidosActivosMesa(mesaId);
});

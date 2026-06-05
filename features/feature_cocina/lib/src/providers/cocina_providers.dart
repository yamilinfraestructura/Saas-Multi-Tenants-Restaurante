import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cocina_models.dart';
import '../repositories/cocina_repository.dart';

final cocinaRepositoryProvider = Provider<CocinaRepository>((ref) {
  return locator<CocinaRepository>();
});

final pedidosActivosStreamProvider = StreamProvider<List<CocinaPedido>>((ref) {
  return ref.watch(cocinaRepositoryProvider).watchPedidosActivos();
});

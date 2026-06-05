import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cocina_models.dart';
import 'cocina_repository.dart';

class SupabaseCocinaRepository implements CocinaRepository {
  SupabaseCocinaRepository(this._client);

  final SupabaseClient _client;

  static const _estadosActivos = [
    'pendiente',
    'en_preparacion',
    'listo',
  ];

  @override
  Stream<List<CocinaPedido>> watchPedidosActivos() {
    return _client
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .order('fecha_creacion')
        .map((rows) {
      return rows
          .where((row) => _estadosActivos.contains(row['estado']))
          .map((e) => CocinaPedido.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<void> updateEstado(String pedidoId, String nuevoEstado) async {
    await _client.from('pedidos').update({'estado': nuevoEstado}).eq('id', pedidoId);
  }
}

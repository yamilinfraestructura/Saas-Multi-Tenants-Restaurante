import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pos_models.dart';
import 'pos_repository.dart';

class SupabasePosRepository implements PosRepository {
  SupabasePosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PosSala>> getSalas() async {
    final data = await _client
        .from('salas')
        .select('id, nombre_sala')
        .eq('estado_sala', 'activa')
        .order('numero_posicion');
    return (data as List)
        .map((e) => PosSala.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PosMesa>> getMesas({String? salaId}) async {
    var query = _client.from('mesas').select();
    if (salaId != null) {
      query = query.eq('sala_id', salaId);
    }
    final data = await query.order('valor_mesa');
    return (data as List)
        .map((e) => PosMesa.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PosPedidoResumen>> getPedidosActivosMesa(String mesaId) async {
    final data = await _client
        .from('pedidos')
        .select('id, mesa_id, nombre_cliente, estado, cobro_pago')
        .eq('mesa_id', mesaId)
        .neq('estado', 'completado');
    return (data as List)
        .map((e) => PosPedidoResumen.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> liberarMesa(String mesaId) async {
    await _client.from('mesas').update({'estado': 'activa'}).eq('id', mesaId);
  }
}

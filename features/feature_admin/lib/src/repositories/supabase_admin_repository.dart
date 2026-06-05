import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import 'admin_repository.dart';

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminCategoria>> getCategorias() async {
    final data = await _client
        .from('categorias')
        .select()
        .order('posicion', ascending: true);
    return (data as List)
        .map((e) => AdminCategoria.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<AdminProducto>> getProductos({String? categoriaId}) async {
    var query = _client.from('productos').select();
    if (categoriaId != null) {
      query = query.eq('categoria_id', categoriaId);
    }
    final data = await query.order('nombre');
    return (data as List)
        .map((e) => AdminProducto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<AdminProducto> createProducto(AdminProducto producto) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'] as String?;
    if (tenantId == null) {
      throw Exception('Sin tenant en sesión');
    }

    final data = await _client
        .from('productos')
        .insert(producto.toInsertJson(tenantId))
        .select()
        .single();

    return AdminProducto.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> deleteProducto(String id) async {
    await _client.from('productos').delete().eq('id', id);
  }

  @override
  Future<List<AdminSala>> getSalas() async {
    final data = await _client
        .from('salas')
        .select()
        .order('numero_posicion', ascending: true);
    return (data as List)
        .map((e) => AdminSala.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<AdminMesa>> getMesas({String? salaId}) async {
    var query = _client.from('mesas').select();
    if (salaId != null) {
      query = query.eq('sala_id', salaId);
    }
    final data = await query.order('valor_mesa');
    return (data as List)
        .map((e) => AdminMesa.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<AdminSala> createSala(String nombre) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'] as String?;
    if (tenantId == null) {
      throw Exception('Sin tenant en sesión');
    }

    final data = await _client
        .from('salas')
        .insert({
          'tenant_id': tenantId,
          'nombre_sala': nombre,
        })
        .select()
        .single();

    return AdminSala.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<AdminMesa> createMesa({
    required String salaId,
    required String valor,
  }) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'] as String?;
    if (tenantId == null) {
      throw Exception('Sin tenant en sesión');
    }

    final data = await _client
        .from('mesas')
        .insert({
          'tenant_id': tenantId,
          'sala_id': salaId,
          'valor_mesa': valor,
        })
        .select()
        .single();

    return AdminMesa.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<AdminUsuario>> getUsuarios() async {
    final data = await _client.from('usuarios').select().order('user_name');
    return (data as List)
        .map((e) => AdminUsuario.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

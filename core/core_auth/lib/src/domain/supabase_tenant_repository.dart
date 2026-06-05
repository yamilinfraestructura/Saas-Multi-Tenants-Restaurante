import 'package:supabase_flutter/supabase_flutter.dart';

import 'tenant_repository.dart';

class SupabaseTenantRepository implements TenantRepository {
  SupabaseTenantRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TenantInfo?> getTenantById(String tenantId) async {
    final data = await _client
        .from('tenants')
        .select('id, nombre_negocio, estado, plan_actual')
        .eq('id', tenantId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return TenantInfo.fromJson(Map<String, dynamic>.from(data));
  }
}

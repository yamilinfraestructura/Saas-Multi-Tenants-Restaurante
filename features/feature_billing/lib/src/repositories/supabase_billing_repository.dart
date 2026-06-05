import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_repository.dart';

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SuscripcionInfo?> getSuscripcionActiva(String tenantId) async {
    final data = await _client
        .from('tenant_suscripciones')
        .select('plan_nombre, monto, moneda, fecha_fin, estado')
        .eq('tenant_id', tenantId)
        .order('fecha_fin', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return SuscripcionInfo.fromJson(Map<String, dynamic>.from(data));
  }
}

import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return locator<BillingRepository>();
});

final suscripcionActivaProvider = FutureProvider<SuscripcionInfo?>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) {
    return null;
  }

  return ref.watch(billingRepositoryProvider).getSuscripcionActiva(tenantId);
});

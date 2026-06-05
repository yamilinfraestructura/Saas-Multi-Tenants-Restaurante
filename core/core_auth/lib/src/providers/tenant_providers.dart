import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tenant_repository.dart';
import 'auth_providers.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return locator<TenantRepository>();
});

final tenantInfoProvider = FutureProvider<TenantInfo?>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) {
    return null;
  }

  ref.watch(authStateProvider);
  return ref.watch(tenantRepositoryProvider).getTenantById(tenantId);
});

final isTenantSuspendedProvider = Provider<bool>((ref) {
  return ref.watch(tenantInfoProvider).valueOrNull?.isSuspendido ?? false;
});

final isTenantInactivoProvider = Provider<bool>((ref) {
  return ref.watch(tenantInfoProvider).valueOrNull?.isInactivo ?? false;
});

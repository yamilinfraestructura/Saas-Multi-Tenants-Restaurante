import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import '../domain/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user;
});

final currentTenantIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  return user.appMetadata['tenant_id'] as String? ??
      user.userMetadata?['tenant_id'] as String?;
});

final currentUserNivelProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  return user.appMetadata['nivel_acceso'] as String? ??
      user.userMetadata?['nivel_acceso'] as String?;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

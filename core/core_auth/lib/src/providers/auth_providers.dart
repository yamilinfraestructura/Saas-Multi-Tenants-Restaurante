import 'package:core_network/core_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import '../utils/auth_session_context.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Sesión actual: el stream puede llegar un tick después de signInWithPassword.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(currentSessionProvider)?.user;
});

final jwtClaimsProvider = Provider<Map<String, dynamic>?>((ref) {
  ref.watch(currentSessionProvider);
  return AuthSessionContext.claimsFrom(Supabase.instance.client);
});

final currentTenantIdProvider = Provider<String?>((ref) {
  ref.watch(currentSessionProvider);
  return AuthSessionContext.tenantId(Supabase.instance.client);
});

final currentUserNivelProvider = Provider<String?>((ref) {
  ref.watch(currentSessionProvider);
  return AuthSessionContext.nivelAcceso(Supabase.instance.client);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

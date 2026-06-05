import 'package:supabase_flutter/supabase_flutter.dart';

import 'jwt_claims.dart';

/// Resuelve claims de sesión (JWT + metadata) para repositorios sin Riverpod.
class AuthSessionContext {
  AuthSessionContext._();

  static Map<String, dynamic>? claimsFrom(SupabaseClient client) {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) {
      return null;
    }
    return decodeJwtPayload(token);
  }

  static String? tenantId(SupabaseClient client) {
    final fromJwt = jwtClaimAsString(claimsFrom(client), 'tenant_id');
    if (fromJwt != null) {
      return fromJwt;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return user.appMetadata['tenant_id'] as String? ??
        user.userMetadata?['tenant_id'] as String?;
  }

  static String? nivelAcceso(SupabaseClient client) {
    final fromJwt = jwtClaimAsString(claimsFrom(client), 'nivel_acceso');
    if (fromJwt != null) {
      return fromJwt;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return user.appMetadata['nivel_acceso'] as String? ??
        user.userMetadata?['nivel_acceso'] as String?;
  }
}

String requireTenantId(SupabaseClient client) {
  final tenantId = AuthSessionContext.tenantId(client);
  if (tenantId == null) {
    throw Exception('Sin tenant en sesión');
  }
  return tenantId;
}

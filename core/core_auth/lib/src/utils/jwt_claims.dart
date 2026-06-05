import 'dart:convert';

/// Lee claims custom del access token (p. ej. tenant_id del Auth Hook).
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod > 0) {
      payload += '=' * (4 - mod);
    }

    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    final decoded = utf8.decode(base64.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? jwtClaimAsString(Map<String, dynamic>? claims, String key) {
  final value = claims?[key];
  if (value == null) {
    return null;
  }
  return value.toString();
}

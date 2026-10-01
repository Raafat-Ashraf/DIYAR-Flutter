import 'dart:convert';

/// Normalizes authentication tokens returned by different API response shapes.
///
/// Older versions of the Apple login endpoint returned a JSON string, so Dio
/// exposed the JWT with leading and trailing quote characters. This helper also
/// accepts a token response object to keep the client compatible with a future
/// structured response.
String normalizeAuthToken(Object? response) {
  Object? value = response;

  if (value is Map) {
    value = value['token'] ?? value['Token'];
  }

  if (value is! String) return '';

  var token = value.trim();
  if (token.isEmpty) return '';

  try {
    final decoded = jsonDecode(token);
    if (decoded is String || decoded is Map) {
      return normalizeAuthToken(decoded);
    }
  } catch (_) {
    // A normal JWT is not JSON, so decoding it is expected to fail.
  }

  if (token.toLowerCase().startsWith('bearer ')) {
    token = token.substring(7).trim();
  }

  return token;
}

bool hasJwtShape(String token) {
  final parts = token.split('.');
  return parts.length == 3 && parts.every((part) => part.isNotEmpty);
}

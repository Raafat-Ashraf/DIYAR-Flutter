import 'dart:convert';

import 'package:diyar/src/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser token normalization', () {
    test('removes JSON quotes from an Apple login token', () {
      final token = _jwt({'sub': 'apple-user', 'email': 'user@example.com'});

      final user = AuthUser.fromToken(jsonEncode(token));

      expect(user.token, token);
      expect(user.id, 'apple-user');
      expect(user.email, 'user@example.com');
    });

    test('normalizes a quoted token restored from secure storage', () {
      final token = _jwt({'sub': 'apple-user', 'email': 'user@example.com'});

      final user = AuthUser.fromJson({
        'id': 'apple-user',
        'email': 'user@example.com',
        'firstName': 'Apple',
        'lastName': 'User',
        'token': jsonEncode(token),
        'expiresIn': 0,
      });

      expect(user.token, token);
    });
  });
}

String _jwt(Map<String, dynamic> claims) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode(claims)}.signature';
}

import 'dart:convert';

import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.token,
    required this.expiresIn,
    required this.roles,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String token;
  final int expiresIn;
  final List<String> roles;

  String get displayName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    return AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      token: token,
      expiresIn: json['expiresIn'] as int? ?? 0,
      roles: _rolesFromToken(token),
    );
  }

  factory AuthUser.fromToken(String token) {
    final claims = _claimsFromToken(token);
    final email = (claims['email'] ?? claims['name'] ?? claims['unique_name'] ?? '')
        .toString();
    final name = (claims['name'] ?? email).toString();
    final firstName = name.contains('@') ? email.split('@').first : name;

    return AuthUser(
      id: (claims['sub'] ?? '').toString(),
      email: email,
      firstName: firstName,
      lastName: '',
      token: token,
      expiresIn: 0,
      roles: _rolesFromClaims(claims),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'token': token,
        'expiresIn': expiresIn,
      };

  static List<String> _rolesFromToken(String token) {
    return _rolesFromClaims(_claimsFromToken(token));
  }

  static Map<String, dynamic> _claimsFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  static List<String> _rolesFromClaims(Map<String, dynamic> claims) {
    final roles = claims['roles'];
    if (roles is List) return roles.whereType<String>().toList();
    if (roles is String) {
      try {
        final decodedRoles = jsonDecode(roles);
        if (decodedRoles is List) {
          return decodedRoles.whereType<String>().toList();
        }
      } catch (_) {
        return [roles];
      }
      return [roles];
    }

    return const [];
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        token,
        expiresIn,
        roles,
      ];
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/account/domain/entities/account_profile.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/saved_account.dart';

class SessionStorage {
  SessionStorage(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'auth_user';
  static const _accountProfileKey = 'account_profile';
  static const _onboardingKey = 'onboarding_seen';
  static const _savedAccountsKey = 'saved_accounts';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<bool> hasSeenOnboarding() async {
    return await _storage.read(key: _onboardingKey) == 'true';
  }

  Future<void> markOnboardingSeen() {
    return _storage.write(key: _onboardingKey, value: 'true');
  }

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<AccountProfile?> readAccountProfile() async {
    final raw = await _storage.read(key: _accountProfileKey);
    if (raw == null || raw.isEmpty) return null;
    return AccountProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAccountProfile(AccountProfile profile) {
    return _storage.write(
      key: _accountProfileKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<void> clearAccountProfile() {
    return _storage.delete(key: _accountProfileKey);
  }

  Future<void> saveSession(AuthUser user) async {
    await _storage.write(key: _accessTokenKey, value: user.token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<List<SavedAccount>> readSavedAccounts() async {
    final raw = await _storage.read(key: _savedAccountsKey);
    if (raw == null || raw.isEmpty) return const [];

    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .map(SavedAccount.fromJson)
        .where((account) => account.email.isNotEmpty)
        .toList();
  }

  Future<void> savePasswordAccount({
    required AuthUser user,
    required String password,
  }) {
    return _upsertSavedAccount(
      SavedAccount(
        email: user.email,
        displayName: user.displayName.isEmpty ? user.email : user.displayName,
        provider: SavedAccountProvider.password,
        password: password,
      ),
    );
  }

  Future<void> saveGoogleAccount(AuthUser user) {
    return _upsertSavedAccount(
      SavedAccount(
        email: user.email,
        displayName: user.displayName.isEmpty ? user.email : user.displayName,
        provider: SavedAccountProvider.google,
        token: user.token,
      ),
    );
  }

  Future<void> _upsertSavedAccount(SavedAccount account) async {
    final accounts = await readSavedAccounts();
    final next = [
      account,
      ...accounts.where(
        (item) =>
            item.email.toLowerCase() != account.email.toLowerCase() ||
            item.provider != account.provider,
      ),
    ];
    await _storage.write(
      key: _savedAccountsKey,
      value: jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _accountProfileKey);
    await _storage.delete(key: _savedAccountsKey);
  }
}

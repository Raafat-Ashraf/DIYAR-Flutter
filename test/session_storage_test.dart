import 'dart:convert';

import 'package:diyar/src/core/storage/session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates a legacy JSON-quoted Apple token from secure storage',
    () async {
      const token = 'header.payload.signature';
      FlutterSecureStorage.setMockInitialValues({
        'access_token': jsonEncode(token),
      });
      final storage = SessionStorage(const FlutterSecureStorage());

      final restoredToken = await storage.readAccessToken();

      expect(restoredToken, token);
    },
  );
}

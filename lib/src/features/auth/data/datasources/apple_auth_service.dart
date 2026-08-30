import 'package:flutter/services.dart';

import '../../../../core/errors/app_failure.dart';

class AppleAuthorization {
  const AppleAuthorization({
    required this.identityToken,
    required this.userIdentifier,
    this.authorizationCode,
    this.email,
    this.givenName,
    this.familyName,
  });

  final String identityToken;
  final String userIdentifier;
  final String? authorizationCode;
  final String? email;
  final String? givenName;
  final String? familyName;

  Map<String, dynamic> toJson() => {
        'identityToken': identityToken,
        'userIdentifier': userIdentifier,
        if (authorizationCode != null) 'authorizationCode': authorizationCode,
        if (email != null) 'email': email,
        if (givenName != null) 'givenName': givenName,
        if (familyName != null) 'familyName': familyName,
      };
}

class AppleAuthService {
  AppleAuthService();

  static const _channel = MethodChannel('diyar/apple_auth');

  Future<AppleAuthorization> signIn() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>('signIn');
      if (response == null) {
        throw const AppFailure(
          message: 'تعذر تسجيل الدخول باستخدام Apple.',
          code: 'Apple',
        );
      }

      final identityToken = response['identityToken']?.toString() ?? '';
      final userIdentifier = response['userIdentifier']?.toString() ?? '';
      if (identityToken.isEmpty || userIdentifier.isEmpty) {
        throw const AppFailure(
          message: 'لم تُرجع Apple بيانات دخول صالحة.',
          code: 'Apple',
        );
      }

      return AppleAuthorization(
        identityToken: identityToken,
        userIdentifier: userIdentifier,
        authorizationCode: response['authorizationCode']?.toString(),
        email: response['email']?.toString(),
        givenName: response['givenName']?.toString(),
        familyName: response['familyName']?.toString(),
      );
    } on PlatformException catch (error) {
      if (error.code == 'APPLE_CANCELED') {
        throw const AppFailure(message: 'تم إلغاء تسجيل الدخول باستخدام Apple.');
      }
      throw AppFailure(
        message: error.message ?? 'تعذر تسجيل الدخول باستخدام Apple.',
        code: error.code.isEmpty ? 'Apple' : error.code,
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        message: 'تعذر تسجيل الدخول باستخدام Apple.',
        code: 'Apple',
      );
    }
  }
}

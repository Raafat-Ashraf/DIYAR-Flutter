import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/backend_message_translator.dart';

class GoogleAuthService {
  GoogleAuthService();

  static const callbackUrl = 'diyar://auth/google-callback';
  static const _channel = MethodChannel('diyar/google_auth');

  Future<String> login() async {
    final completer = Completer<String>();

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onGoogleCallback' || completer.isCompleted) return;
      _completeFromUrl(completer, call.arguments?.toString());
    });

    final loginUri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.googleLogin.substring(1)}',
    ).replace(queryParameters: {'returnUrl': callbackUrl});

    final initialCallback = await _channel.invokeMethod<String>(
      'consumeInitialGoogleCallback',
    );
    if (initialCallback != null && initialCallback.isNotEmpty) {
      _completeFromUrl(completer, initialCallback);
    }

    final launched = await _channel.invokeMethod<bool>(
      'startGoogleLogin',
      {'url': loginUri.toString()},
    );

    if (launched != true) {
      throw const AppFailure(message: 'تعذر فتح تسجيل الدخول عبر Google.');
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw const AppFailure(
            message: 'انتهت مهلة تسجيل الدخول عبر Google. حاول مرة أخرى.',
          );
        },
      );
    } finally {
      _channel.setMethodCallHandler(null);
    }
  }

  void _completeFromUrl(Completer<String> completer, String? url) {
    if (url == null || url.isEmpty || completer.isCompleted) return;
    final uri = Uri.parse(url);
    if (uri.scheme != 'diyar' ||
        uri.host != 'auth' ||
        uri.path != '/google-callback') {
      return;
    }

    final fragmentParams = Uri.splitQueryString(uri.fragment);
    final token = fragmentParams['token'] ?? uri.queryParameters['token'];
    final error = fragmentParams['error'] ?? uri.queryParameters['error'];

    if (token != null && token.isNotEmpty) {
      completer.complete(token);
      return;
    }

    final errorCode = fragmentParams['code'] ?? uri.queryParameters['code'];
    final errorMsg = error ?? 'Unable to login user';
    // If error is Arabic (server-translated) use it directly; otherwise translate
    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(errorMsg);
    completer.completeError(
      AppFailure(
        message: isArabic
            ? errorMsg
            : BackendMessageTranslator.translate(errorMsg, code: errorCode ?? 'Google'),
        code: errorCode ?? 'Google',
      ),
    );
  }
}

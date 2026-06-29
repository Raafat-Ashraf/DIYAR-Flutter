import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import 'local_notification_service.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM auto-displays notification when message.notification != null and app is killed/background.
  // Only show via flutter_local_notifications for data-only messages.
  if (message.notification != null) return;

  await LocalNotificationService.init();
  await LocalNotificationService.show(
    id: message.hashCode,
    title: message.data['title'] ?? 'إشعار جديد',
    body: message.data['body'] ?? '',
  );
}

class FcmService {
  FcmService(this._apiClient);

  final ApiClient _apiClient;

  /// Called when user taps a notification (background or killed state).
  void Function()? onNotificationTap;

  Future<void> init() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages are handled by SignalR — no duplicate show() here.

    // App was in BACKGROUND → user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onNotificationTap?.call());

    // App was KILLED → user tapped the notification to open it
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Delay to let auth + profile load before navigating
      Future.delayed(const Duration(seconds: 2), () => onNotificationTap?.call());
    }

    await _registerToken();
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendToken);
  }

  Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await _apiClient.put<dynamic>(
        ApiConstants.registerDeviceToken,
        data: '"$token"',
      );
      debugPrint('[FCM] Token registered');
    } catch (e) {
      debugPrint('[FCM] Failed to send token: $e');
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'src/app/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/services/fcm_service.dart';
import 'src/core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotificationService.init();
  // Register background FCM handler before app starts
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await configureDependencies();
  runApp(const DiyarApp());
}

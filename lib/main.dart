import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'src/app/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/services/fcm_service.dart';
import 'src/core/services/local_notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await configureDependencies();

    // Firebase and notifications are optional startup services. A
    // configuration or platform error must never block the main application.
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (error, stackTrace) {
      debugPrint('[Startup] Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await LocalNotificationService.init();
    } catch (error, stackTrace) {
      debugPrint('[Startup] Local notifications initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _retry() {
    setState(() => _initialization = _initializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const DiyarApp();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تعذر تشغيل التطبيق',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DIYAR - ديار',
                            style: TextStyle(
                              color: Color(0xFF004B82),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 24),
                          CircularProgressIndicator(color: Color(0xFFF47B20)),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

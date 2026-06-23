import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/di/service_locator.dart';
import '../core/services/fcm_service.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/signalr_service.dart';
import '../features/account/presentation/cubit/account_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class DiyarApp extends StatelessWidget {
  const DiyarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiyarAppView();
  }
}

class DiyarAppView extends StatefulWidget {
  const DiyarAppView({super.key});

  @override
  State<DiyarAppView> createState() => _DiyarAppViewState();
}

class _DiyarAppViewState extends State<DiyarAppView> {
  late final AuthBloc _authBloc;
  late final AccountCubit _accountCubit;
  late final GoRouter _router;
  late final SignalRService _signalR;
  late final FcmService _fcm;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _accountCubit = getIt<AccountCubit>();
    _signalR = getIt<SignalRService>();
    _fcm = getIt<FcmService>();
    _router = AppRouter.create(_authBloc, _accountCubit);
    _authBloc.add(const AuthStarted());

    _signalR.addListener(_onNotification);
  }

  void _onNotification(NotificationPayload payload) {
    // show local notification with custom sound
    LocalNotificationService.show(
      id: payload.id,
      title: payload.title,
      body: payload.content,
    );

    // show banner
    final ctx = _router.routerDelegate.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payload.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                payload.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  void dispose() {
    _signalR.removeListener(_onNotification);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _accountCubit),
        BlocProvider.value(value: getIt<NotificationsCubit>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.user != current.user,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.read<AccountCubit>().loadProfile();
            context.read<NotificationsCubit>().load();
            _signalR.connect();
            _fcm.init();
            _requestNotificationPermission();
          } else if (state.status == AuthStatus.unauthenticated) {
            context.read<AccountCubit>().clear();
            _signalR.disconnect();
          }
        },
        child: MaterialApp.router(
          title: 'DIYAR',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}

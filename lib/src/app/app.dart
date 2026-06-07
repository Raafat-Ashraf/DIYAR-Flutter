import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_locator.dart';
import '../features/account/presentation/cubit/account_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _accountCubit = getIt<AccountCubit>();
    _router = AppRouter.create(_authBloc, _accountCubit);
    _authBloc.add(const AuthStarted());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _accountCubit),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.user != current.user,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.read<AccountCubit>().loadProfile();
          } else if (state.status == AuthStatus.unauthenticated) {
            context.read<AccountCubit>().clear();
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

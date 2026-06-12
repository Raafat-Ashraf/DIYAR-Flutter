import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/domain/entities/account_profile.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/account/presentation/pages/account_error_page.dart';
import '../../features/account/presentation/pages/account_role_selection_page.dart';
import '../../features/account/presentation/pages/pending_approval_page.dart';
import '../../features/account/presentation/pages/profile_page.dart';
import '../../features/account/presentation/pages/rejected_account_page.dart';
import '../../features/account/presentation/pages/verify_account_page.dart';
import '../../features/admin/presentation/pages/pending_verification_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/specializations/presentation/admin/pages/admin_specializations_page.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static GoRouter create(
    AuthBloc authBloc,
    AccountCubit accountCubit,
  ) => GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) =>
            ResetPasswordPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (_, _) => const AccountRoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyAccount,
        builder: (_, state) {
          final profileType = accountCubit.state.profile?.providerType;
          final queryType = ProviderType.fromApi(
            state.uri.queryParameters['type'],
          );
          return VerifyAccountPage(
            providerType: queryType ?? profileType ?? ProviderType.client,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (_, _) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: AppRoutes.rejectedAccount,
        builder: (_, _) => const RejectedAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.accountError,
        builder: (_, _) => const AccountErrorPage(),
      ),
      GoRoute(
        path: AppRoutes.googleCallback,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.adminPendingVerification,
        builder: (_, _) => const PendingVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSpecializations,
        builder: (_, _) => const AdminSpecializationsPage(),
      ),
    ],
    redirect: (context, state) {
      final authState = authBloc.state;
      final accountState = accountCubit.state;
      final location = state.uri.path;
      final publicRoutes = {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.verifyEmail,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.googleCallback,
      };

      if (authState.status == AuthStatus.checking) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState.status == AuthStatus.unauthenticated &&
          location == AppRoutes.splash) {
        return AppRoutes.onboarding;
      }

      if (authState.status == AuthStatus.unauthenticated &&
          !publicRoutes.contains(location)) {
        return AppRoutes.onboarding;
      }

      if (authState.status != AuthStatus.authenticated) return null;

      if (accountState.status == AccountStatus.initial ||
          accountState.status == AccountStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (accountState.status == AccountStatus.failure) {
        return location == AppRoutes.accountError
            ? null
            : AppRoutes.accountError;
      }

      final profile = accountState.profile;
      if (profile == null) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final expected = _expectedRouteFor(profile);
      final isVerifyWithSelectedType =
          location == AppRoutes.verifyAccount &&
          profile.providerType == null &&
          ProviderType.fromApi(state.uri.queryParameters['type']) != null;

      if (isVerifyWithSelectedType) return null;

      final accountRoutes = {
        AppRoutes.roleSelection,
        AppRoutes.verifyAccount,
        AppRoutes.pendingApproval,
        AppRoutes.rejectedAccount,
        AppRoutes.home,
        AppRoutes.profile,
        AppRoutes.accountError,
      };

      final approvedSecondaryRoute =
          expected == AppRoutes.home && location == AppRoutes.profile;

      if (publicRoutes.contains(location) ||
          accountRoutes.contains(location) &&
              location != expected &&
              !approvedSecondaryRoute) {
        return expected;
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStreams([
      authBloc.stream,
      accountCubit.stream,
    ]),
  );

  static String _expectedRouteFor(AccountProfile profile) {
    if (profile.providerType == null) return AppRoutes.roleSelection;

    return switch (profile.verificationStatus) {
      VerificationStatus.pending => AppRoutes.pendingApproval,
      VerificationStatus.approved => AppRoutes.home,
      VerificationStatus.rejected => AppRoutes.rejectedAccount,
      VerificationStatus.notSubmitted => AppRoutes.verifyAccount,
    };
  }
}

class GoRouterRefreshStreams extends ChangeNotifier {
  GoRouterRefreshStreams(List<Stream<dynamic>> streams) {
    notifyListeners();
    _subscriptions = streams
        .map(
          (stream) =>
              stream.asBroadcastStream().listen((_) => notifyListeners()),
        )
        .toList();
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

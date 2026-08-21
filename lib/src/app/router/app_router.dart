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
import '../../features/admin/presentation/pages/admin_broadcast_page.dart';
import '../../features/account/presentation/pages/edit_profile_page.dart';
import '../../features/account/presentation/pages/change_password_page.dart';
import '../../features/account/presentation/pages/edit_cities_page.dart';
import '../../features/account/presentation/pages/edit_specializations_page.dart';
import '../../features/account/presentation/pages/delete_account_page.dart';
import '../../features/account/presentation/pages/privacy_policy_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_requests_page.dart';
import '../../features/admin/presentation/pages/admin_statistics_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/requests/domain/entities/request.dart';
import '../../features/requests/presentation/pages/create_request_page.dart';
import '../../features/requests/presentation/pages/my_requests_page.dart';
import '../../features/showcases/presentation/pages/showcases_list_page.dart';
import '../../features/requests/presentation/pages/request_details_page.dart';
import '../../features/requests/presentation/pages/requests_page.dart';
import '../../features/showcases/domain/entities/showcase.dart';
import '../../features/showcases/presentation/pages/create_showcase_page.dart';
import '../../features/showcases/presentation/pages/showcase_details_page.dart';
import '../../features/showcases/presentation/pages/trending_page.dart';
import '../../features/specializations/presentation/admin/pages/admin_specializations_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_detail_page.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/requests/presentation/pages/request_by_id_page.dart';
import '../../features/quotations/presentation/pages/quotations_page.dart';
import '../../features/quotations/presentation/pages/create_quotation_page.dart';
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
      // OAuth callback route - handled via MethodChannel, redirect away immediately
      GoRoute(
        path: AppRoutes.googleCallback,
        redirect: (context, state) => AppRoutes.login,
      ),
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
      GoRoute(
        path: AppRoutes.createShowcase,
        builder: (_, _) => const CreateShowcasePage(),
      ),
      GoRoute(
        path: AppRoutes.trending,
        builder: (_, _) => const TrendingPage(),
      ),
      GoRoute(
        path: AppRoutes.showcaseDetails,
        builder: (_, state) =>
            ShowcaseDetailsPage(showcase: state.extra as Showcase),
      ),
      GoRoute(
        path: AppRoutes.createRequest,
        builder: (_, _) => const CreateRequestPage(),
      ),
      GoRoute(
        path: AppRoutes.requests,
        builder: (_, _) => const RequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.requestDetails,
        builder: (_, state) =>
            RequestDetailsPage(request: state.extra as Request),
      ),
      GoRoute(
        path: AppRoutes.myRequests,
        builder: (_, state) =>
            MyRequestsPage(clientId: state.uri.queryParameters['clientId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.showcasesList,
        builder: (_, _) => const ShowcasesListPage(),
      ),
      GoRoute(
        path: AppRoutes.quotations,
        builder: (_, state) {
          final raw = state.uri.queryParameters['requestId'];
          final id = raw != null ? int.tryParse(raw) : null;
          return QuotationsPage(requestId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.createQuotation,
        builder: (_, state) =>
            CreateQuotationPage(requestId: int.parse(state.uri.queryParameters['requestId'] ?? '0')),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationDetail,
        builder: (_, state) =>
            NotificationDetailPage(notification: state.extra as NotificationItem),
      ),
      GoRoute(
        path: AppRoutes.adminBroadcast,
        builder: (_, _) => const AdminBroadcastPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editCities,
        builder: (_, _) => const EditCitiesPage(),
      ),
      GoRoute(
        path: AppRoutes.editSpecializations,
        builder: (_, _) => const EditSpecializationsPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, _) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (_, _) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (_, _) => const AdminUsersPage(),
      ),
      GoRoute(
        path: AppRoutes.adminRequests,
        builder: (_, _) => const AdminRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminStatistics,
        builder: (_, _) => const AdminStatisticsPage(),
      ),
      GoRoute(
        path: AppRoutes.requestById,
        builder: (_, state) => RequestByIdPage(
          requestId: int.parse(state.uri.queryParameters['id'] ?? '0'),
        ),
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
          (accountState.status == AccountStatus.loading &&
              accountState.profile == null)) {
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
          (profile.providerType == null ||
              profile.verificationStatus == VerificationStatus.rejected) &&
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

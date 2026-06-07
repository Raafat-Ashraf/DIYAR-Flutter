import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/usecases/check_session_use_case.dart';
import '../../domain/usecases/confirm_email_use_case.dart';
import '../../domain/usecases/forgot_password_use_case.dart';
import '../../domain/usecases/get_saved_accounts_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/login_with_google_use_case.dart';
import '../../domain/usecases/login_with_saved_account_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/resend_confirmation_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.checkSession,
    required this.getSavedAccounts,
    required this.login,
    required this.loginWithSavedAccount,
    required this.loginWithGoogle,
    required this.register,
    required this.confirmEmail,
    required this.resendConfirmation,
    required this.forgotPassword,
    required this.resetPassword,
    required this.logout,
  }) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSavedAccountsRequested>(_onSavedAccountsRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSavedAccountSelected>(_onSavedAccountSelected);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthConfirmEmailSubmitted>(_onConfirmEmailSubmitted);
    on<AuthResendConfirmationSubmitted>(_onResendConfirmationSubmitted);
    on<AuthForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<AuthResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final CheckSessionUseCase checkSession;
  final GetSavedAccountsUseCase getSavedAccounts;
  final LoginUseCase login;
  final LoginWithSavedAccountUseCase loginWithSavedAccount;
  final LoginWithGoogleUseCase loginWithGoogle;
  final RegisterUseCase register;
  final ConfirmEmailUseCase confirmEmail;
  final ResendConfirmationUseCase resendConfirmation;
  final ForgotPasswordUseCase forgotPassword;
  final ResetPasswordUseCase resetPassword;
  final LogoutUseCase logout;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.checking, clearMessages: true));
    try {
      final user = await checkSession();
      final accounts = await getSavedAccounts();
      emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          savedAccounts: accounts,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSavedAccountsRequested(
    AuthSavedAccountsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final accounts = await getSavedAccounts();
    emit(state.copyWith(savedAccounts: accounts));
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => login(event.email, event.password),
      onSuccess: (user) => state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'أهلًا بعودتك يا ${user.firstName}.',
      ),
    );
  }

  Future<void> _onSavedAccountSelected(
    AuthSavedAccountSelected event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => loginWithSavedAccount(event.account),
      onSuccess: (user) => state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'تم تسجيل الدخول بنجاح.',
      ),
    );
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => loginWithGoogle(),
      onSuccess: (user) => state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'تم تسجيل الدخول عبر Google بنجاح.',
      ),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => register(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        confirmPassword: event.confirmPassword,
      ),
      onSuccess: (message) => state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
        pendingEmail: event.email,
      ),
    );
  }

  Future<void> _onConfirmEmailSubmitted(
    AuthConfirmEmailSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => confirmEmail(event.email, event.otp),
      onSuccess: (message) => state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
        pendingEmail: event.email,
      ),
    );
  }

  Future<void> _onResendConfirmationSubmitted(
    AuthResendConfirmationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => resendConfirmation(event.email),
      onSuccess: (message) => state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
        pendingEmail: event.email,
      ),
    );
  }

  Future<void> _onForgotPasswordSubmitted(
    AuthForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => forgotPassword(event.email),
      onSuccess: (message) => state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
        pendingEmail: event.email,
      ),
    );
  }

  Future<void> _onResetPasswordSubmitted(
    AuthResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await _guard(
      emit,
      action: () => resetPassword(
        email: event.email,
        otp: event.otp,
        newPassword: event.newPassword,
      ),
      onSuccess: (message) => state.copyWith(
        status: AuthStatus.unauthenticated,
        successMessage: message,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logout();
    final accounts = await getSavedAccounts();
    emit(
      AuthState(
        status: AuthStatus.unauthenticated,
        savedAccounts: accounts,
      ),
    );
  }

  Future<void> _guard<T>(
    Emitter<AuthState> emit, {
    required Future<T> Function() action,
    required AuthState Function(T value) onSuccess,
  }) async {
    try {
      final value = await action();
      emit(onSuccess(value));
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
        ),
      );
    }
  }
}

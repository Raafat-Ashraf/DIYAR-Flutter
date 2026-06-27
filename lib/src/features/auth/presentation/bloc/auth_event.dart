part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSavedAccountsRequested extends AuthEvent {
  const AuthSavedAccountsRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSavedAccountSelected extends AuthEvent {
  const AuthSavedAccountSelected(this.account);

  final SavedAccount account;

  @override
  List<Object?> get props => [account];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phoneNumber,
        password,
        confirmPassword,
      ];
}

class AuthConfirmEmailSubmitted extends AuthEvent {
  const AuthConfirmEmailSubmitted({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class AuthResendConfirmationSubmitted extends AuthEvent {
  const AuthResendConfirmationSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthForgotPasswordSubmitted extends AuthEvent {
  const AuthForgotPasswordSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordSubmitted extends AuthEvent {
  const AuthResetPasswordSubmitted({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  @override
  List<Object?> get props => [email, otp, newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthBanDetected extends AuthEvent {
  const AuthBanDetected({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

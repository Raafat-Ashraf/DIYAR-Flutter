part of 'auth_bloc.dart';

enum AuthStatus {
  checking,
  unauthenticated,
  authenticated,
  loading,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.pendingEmail,
    this.savedAccounts = const [],
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingEmail;
  final List<SavedAccount> savedAccounts;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    String? successMessage,
    String? pendingEmail,
    List<SavedAccount>? savedAccounts,
    bool clearMessages = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      savedAccounts: savedAccounts ?? this.savedAccounts,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        successMessage,
        pendingEmail,
        savedAccounts,
      ];
}

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
    this.errorCode,
    this.successMessage,
    this.pendingEmail,
    this.savedAccounts = const [],
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final String? errorCode;
  final String? successMessage;
  final String? pendingEmail;
  final List<SavedAccount> savedAccounts;

  bool get isLoading => status == AuthStatus.loading;
  bool get isBanned => errorCode == 'User.Banned';

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    String? errorCode,
    String? successMessage,
    String? pendingEmail,
    List<SavedAccount>? savedAccounts,
    bool clearMessages = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      errorCode: clearMessages ? null : errorCode ?? this.errorCode,
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
        errorCode,
        successMessage,
        pendingEmail,
        savedAccounts,
      ];
}

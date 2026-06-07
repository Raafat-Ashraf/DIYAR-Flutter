import '../../../../core/storage/session_storage.dart';
import '../../../../core/errors/app_failure.dart';
import '../datasources/google_auth_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/saved_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_request_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._sessionStorage,
    this._googleAuthService,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;
  final GoogleAuthService _googleAuthService;

  @override
  Future<AuthUser?> checkSession() => _sessionStorage.readUser();

  @override
  Future<List<SavedAccount>> savedAccounts() {
    return _sessionStorage.readSavedAccounts();
  }

  @override
  Future<AuthUser> login(String email, String password) async {
    final user = await _remoteDataSource.login(
      LoginRequestModel(email: email.trim(), password: password),
    );
    await _sessionStorage.saveSession(user);
    await _sessionStorage.savePasswordAccount(user: user, password: password);
    return user;
  }

  @override
  Future<AuthUser> loginWithSavedAccount(SavedAccount account) async {
    if (account.provider == SavedAccountProvider.password) {
      final password = account.password;
      if (password == null || password.isEmpty) {
        throw const AppFailure(message: 'لا توجد كلمة مرور محفوظة لهذا الحساب.');
      }
      return login(account.email, password);
    }

    final token = account.token;
    if (token == null || token.isEmpty) {
      throw const AppFailure(message: 'لا يوجد رمز دخول محفوظ لهذا الحساب.');
    }

    final user = AuthUser.fromToken(token);
    await _sessionStorage.saveSession(user);
    return user;
  }

  @override
  Future<AuthUser> loginWithGoogle() async {
    final token = await _googleAuthService.login();
    final user = AuthUser.fromToken(token);
    await _sessionStorage.saveSession(user);
    await _sessionStorage.saveGoogleAccount(user);
    return user;
  }

  @override
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) {
    return _remoteDataSource.register(
      RegisterRequestModel(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
  }

  @override
  Future<String> confirmEmail(String email, String otp) {
    return _remoteDataSource.confirmEmail(email.trim(), otp.trim());
  }

  @override
  Future<String> resendConfirmationEmail(String email) {
    return _remoteDataSource.resendConfirmationEmail(email.trim());
  }

  @override
  Future<String> forgotPassword(String email) {
    return _remoteDataSource.forgotPassword(email.trim());
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _remoteDataSource.resetPassword(
      email.trim(),
      otp.trim(),
      newPassword,
    );
  }

  @override
  Future<void> logout() => _sessionStorage.clearSession();
}

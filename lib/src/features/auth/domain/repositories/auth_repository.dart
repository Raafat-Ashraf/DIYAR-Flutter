import '../entities/auth_user.dart';
import '../entities/saved_account.dart';

abstract class AuthRepository {
  Future<AuthUser?> checkSession();
  Future<List<SavedAccount>> savedAccounts();
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> loginWithSavedAccount(SavedAccount account);
  Future<AuthUser> loginWithGoogle();
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  });
  Future<String> confirmEmail(String email, String otp);
  Future<String> resendConfirmationEmail(String email);
  Future<String> forgotPassword(String email);
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
  Future<void> logout();
}

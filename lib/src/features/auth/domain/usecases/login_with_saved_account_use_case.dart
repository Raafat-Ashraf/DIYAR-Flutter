import '../entities/auth_user.dart';
import '../entities/saved_account.dart';
import '../repositories/auth_repository.dart';

class LoginWithSavedAccountUseCase {
  const LoginWithSavedAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(SavedAccount account) {
    return _repository.loginWithSavedAccount(account);
  }
}

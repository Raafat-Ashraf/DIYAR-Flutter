import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  const LoginWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call() => _repository.loginWithGoogle();
}

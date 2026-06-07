import '../repositories/auth_repository.dart';

class ResendConfirmationUseCase {
  const ResendConfirmationUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call(String email) {
    return _repository.resendConfirmationEmail(email);
  }
}

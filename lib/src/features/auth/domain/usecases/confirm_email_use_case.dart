import '../repositories/auth_repository.dart';

class ConfirmEmailUseCase {
  const ConfirmEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call(String email, String otp) {
    return _repository.confirmEmail(email, otp);
  }
}

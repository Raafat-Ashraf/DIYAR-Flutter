import '../entities/account_profile.dart';
import '../repositories/account_repository.dart';

class VerifyAccountUseCase {
  const VerifyAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(VerifyAccountInput input) {
    return _repository.verifyAccount(input);
  }
}

import '../entities/account_profile.dart';
import '../repositories/account_repository.dart';

class GetAccountProfileUseCase {
  const GetAccountProfileUseCase(this._repository);

  final AccountRepository _repository;

  Future<AccountProfile> call() => _repository.profile();
}

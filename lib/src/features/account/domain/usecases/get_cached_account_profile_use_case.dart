import '../entities/account_profile.dart';
import '../repositories/account_repository.dart';

class GetCachedAccountProfileUseCase {
  const GetCachedAccountProfileUseCase(this._repository);

  final AccountRepository _repository;

  Future<AccountProfile?> call() => _repository.cachedProfile();
}

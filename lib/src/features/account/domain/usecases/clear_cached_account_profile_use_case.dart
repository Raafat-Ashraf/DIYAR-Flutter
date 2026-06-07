import '../repositories/account_repository.dart';

class ClearCachedAccountProfileUseCase {
  const ClearCachedAccountProfileUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.clearCachedProfile();
}

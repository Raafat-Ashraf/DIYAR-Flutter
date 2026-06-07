import '../entities/saved_account.dart';
import '../repositories/auth_repository.dart';

class GetSavedAccountsUseCase {
  const GetSavedAccountsUseCase(this._repository);

  final AuthRepository _repository;

  Future<List<SavedAccount>> call() => _repository.savedAccounts();
}

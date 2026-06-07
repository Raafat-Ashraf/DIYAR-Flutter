import '../entities/account_profile.dart';
import '../repositories/account_repository.dart';

class GetGovernoratesUseCase {
  const GetGovernoratesUseCase(this._repository);

  final AccountRepository _repository;

  Future<List<Governorate>> call() => _repository.governorates();
}

import '../entities/account_profile.dart';
import '../repositories/account_repository.dart';

class GetGovernorateCitiesUseCase {
  const GetGovernorateCitiesUseCase(this._repository);

  final AccountRepository _repository;

  Future<GovernorateCities> call(int governorateId) =>
      _repository.governorateCities(governorateId);
}

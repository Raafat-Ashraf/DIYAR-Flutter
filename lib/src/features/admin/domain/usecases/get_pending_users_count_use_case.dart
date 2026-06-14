import '../repositories/admin_repository.dart';

class GetPendingUsersCountUseCase {
  const GetPendingUsersCountUseCase(this._repository);

  final AdminRepository _repository;

  Future<int> call() => _repository.getPendingUsersCount();
}

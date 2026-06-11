import '../entities/pending_user.dart';
import '../repositories/admin_repository.dart';

class GetPendingUsersUseCase {
  const GetPendingUsersUseCase(this._repository);

  final AdminRepository _repository;

  Future<List<PendingUser>> call() => _repository.getPendingUsers();
}

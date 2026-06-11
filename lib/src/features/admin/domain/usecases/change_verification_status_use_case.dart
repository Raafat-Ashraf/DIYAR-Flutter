import '../../../account/domain/entities/account_profile.dart';
import '../repositories/admin_repository.dart';

class ChangeVerificationStatusUseCase {
  const ChangeVerificationStatusUseCase(this._repository);

  final AdminRepository _repository;

  Future<void> call({
    required String userId,
    required VerificationStatus status,
    String? rejectionReason,
  }) {
    return _repository.changeVerificationStatus(
      userId: userId,
      status: status,
      rejectionReason: rejectionReason,
    );
  }
}

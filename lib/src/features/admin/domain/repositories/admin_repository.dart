import '../../../account/domain/entities/account_profile.dart';
import '../entities/pending_user.dart';

abstract class AdminRepository {
  Future<List<PendingUser>> getPendingUsers();

  Future<void> changeVerificationStatus({
    required String userId,
    required VerificationStatus status,
    String? rejectionReason,
  });
}

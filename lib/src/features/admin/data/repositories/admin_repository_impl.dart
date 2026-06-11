import '../../../account/domain/entities/account_profile.dart';
import '../../domain/entities/pending_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<List<PendingUser>> getPendingUsers() {
    return _remoteDataSource.getPendingUsers();
  }

  @override
  Future<void> changeVerificationStatus({
    required String userId,
    required VerificationStatus status,
    String? rejectionReason,
  }) {
    return _remoteDataSource.changeVerificationStatus(
      userId: userId,
      status: status,
      rejectionReason: rejectionReason,
    );
  }
}

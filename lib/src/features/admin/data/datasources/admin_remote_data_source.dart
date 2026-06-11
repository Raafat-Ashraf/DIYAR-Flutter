import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../domain/entities/pending_user.dart';
import '../models/change_verification_status_request_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<PendingUser>> getPendingUsers();

  Future<void> changeVerificationStatus({
    required String userId,
    required VerificationStatus status,
    String? rejectionReason,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<PendingUser>> getPendingUsers() async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.getAllPendingUsers,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(PendingUser.fromJson)
        .toList();
  }

  @override
  Future<void> changeVerificationStatus({
    required String userId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    await _client.put<dynamic>(
      ApiConstants.changeUserVerificationStatus,
      queryParameters: {'userId': userId},
      data: ChangeVerificationStatusRequestModel(
        status: status,
        rejectionReason: rejectionReason,
      ).toJson(),
    );
  }
}

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/account_profile.dart';
import '../models/verify_account_request_model.dart';

abstract class AccountRemoteDataSource {
  Future<AccountProfile> profile();
  Future<List<Governorate>> governorates();
  Future<GovernorateCities> governorateCities(int governorateId);
  Future<void> verifyAccount(VerifyAccountRequestModel request);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  const AccountRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AccountProfile> profile() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.accountProfile,
    );
    return AccountProfile.fromJson(response);
  }

  @override
  Future<List<Governorate>> governorates() async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.governorates,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(Governorate.fromJson)
        .where((item) => item.id > 0 && item.name.isNotEmpty)
        .toList();
  }

  @override
  Future<GovernorateCities> governorateCities(int governorateId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.governorateById,
      queryParameters: {'id': governorateId},
    );
    return GovernorateCities.fromJson(response);
  }

  @override
  Future<void> verifyAccount(VerifyAccountRequestModel request) async {
    await _client.put<dynamic>(
      ApiConstants.verifyAccount,
      data: await request.toFormData(),
    );
  }
}

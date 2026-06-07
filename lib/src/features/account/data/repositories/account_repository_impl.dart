import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';
import '../models/verify_account_request_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remoteDataSource, this._sessionStorage);

  final AccountRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<AccountProfile?> cachedProfile() {
    return _sessionStorage.readAccountProfile();
  }

  @override
  Future<AccountProfile> profile() async {
    final profile = await _remoteDataSource.profile();
    await _sessionStorage.saveAccountProfile(profile);
    return profile;
  }

  @override
  Future<List<Governorate>> governorates() {
    return _remoteDataSource.governorates();
  }

  @override
  Future<void> verifyAccount(VerifyAccountInput input) {
    return _remoteDataSource.verifyAccount(VerifyAccountRequestModel(input));
  }

  @override
  Future<void> clearCachedProfile() {
    return _sessionStorage.clearAccountProfile();
  }
}

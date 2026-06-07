import '../entities/account_profile.dart';

abstract class AccountRepository {
  Future<AccountProfile?> cachedProfile();
  Future<AccountProfile> profile();
  Future<List<Governorate>> governorates();
  Future<void> verifyAccount(VerifyAccountInput input);
  Future<void> clearCachedProfile();
}

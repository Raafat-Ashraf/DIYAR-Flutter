import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/usecases/clear_cached_account_profile_use_case.dart';
import '../../domain/usecases/get_account_profile_use_case.dart';
import '../../domain/usecases/get_cached_account_profile_use_case.dart';
import '../../domain/usecases/get_governorate_cities_use_case.dart';
import '../../domain/usecases/get_governorates_use_case.dart';
import '../../domain/usecases/verify_account_use_case.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({
    required this.getCachedProfile,
    required this.getProfile,
    required this.getGovernorates,
    required this.getGovernorateCities,
    required this.verifyAccount,
    required this.clearCachedProfile,
  }) : super(const AccountState());

  final GetCachedAccountProfileUseCase getCachedProfile;
  final GetAccountProfileUseCase getProfile;
  final GetGovernoratesUseCase getGovernorates;
  final GetGovernorateCitiesUseCase getGovernorateCities;
  final VerifyAccountUseCase verifyAccount;
  final ClearCachedAccountProfileUseCase clearCachedProfile;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: AccountStatus.loading, clearMessages: true));
    try {
      final cached = await getCachedProfile();
      if (cached != null) {
        emit(state.copyWith(status: AccountStatus.ready, profile: cached));
      }

      final fresh = await getProfile();
      emit(
        state.copyWith(
          status: AccountStatus.ready,
          profile: fresh,
          clearMessages: true,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'تعذر تحميل بيانات الحساب.',
        ),
      );
    }
  }

  Future<void> loadGovernorates() async {
    if (state.governorates.isNotEmpty) return;
    try {
      final items = await getGovernorates();
      emit(state.copyWith(governorates: items));
    } on AppFailure catch (failure) {
      emit(state.copyWith(errorMessage: failure.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'تعذر تحميل المحافظات.'));
    }
  }

  Future<void> submitVerification(VerifyAccountInput input) async {
    emit(state.copyWith(status: AccountStatus.submitting, clearMessages: true));
    try {
      await verifyAccount(input);
      final fresh = await getProfile();
      emit(
        state.copyWith(
          status: AccountStatus.ready,
          profile: fresh,
          successMessage: 'تم إرسال بيانات التحقق بنجاح.',
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: AccountStatus.ready,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AccountStatus.ready,
          errorMessage: 'تعذر إرسال بيانات التحقق.',
        ),
      );
    }
  }

  Future<void> clear() async {
    await clearCachedProfile();
    emit(const AccountState());
  }
}

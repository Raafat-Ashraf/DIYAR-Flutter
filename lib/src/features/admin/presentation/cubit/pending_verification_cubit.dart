import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../domain/entities/pending_user.dart';
import '../../domain/usecases/change_verification_status_use_case.dart';
import '../../domain/usecases/get_pending_users_use_case.dart';

part 'pending_verification_state.dart';

class PendingVerificationCubit extends Cubit<PendingVerificationState> {
  PendingVerificationCubit({
    required this.getPendingUsers,
    required this.changeVerificationStatus,
  }) : super(const PendingVerificationState());

  final GetPendingUsersUseCase getPendingUsers;
  final ChangeVerificationStatusUseCase changeVerificationStatus;

  Future<void> loadPendingUsers() async {
    emit(
      state.copyWith(
        status: PendingVerificationStatus.loading,
        clearMessages: true,
      ),
    );
    try {
      final users = await getPendingUsers();
      emit(
        state.copyWith(status: PendingVerificationStatus.loaded, users: users),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: PendingVerificationStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PendingVerificationStatus.failure,
          errorMessage: 'تعذر تحميل طلبات التحقق.',
        ),
      );
    }
  }

  Future<void> approveUser(String userId) {
    return _changeStatus(
      userId: userId,
      status: VerificationStatus.approved,
      successMessage: 'تمت الموافقة على الحساب بنجاح.',
    );
  }

  Future<void> rejectUser(String userId, String reason) {
    return _changeStatus(
      userId: userId,
      status: VerificationStatus.rejected,
      rejectionReason: reason,
      successMessage: 'تم رفض الحساب بنجاح.',
    );
  }

  Future<void> _changeStatus({
    required String userId,
    required VerificationStatus status,
    required String successMessage,
    String? rejectionReason,
  }) async {
    emit(
      state.copyWith(
        processingUserIds: {...state.processingUserIds, userId},
        clearMessages: true,
      ),
    );
    try {
      await changeVerificationStatus(
        userId: userId,
        status: status,
        rejectionReason: rejectionReason,
      );
      final users = state.users.where((user) => user.id != userId).toList();
      final processing = {...state.processingUserIds}..remove(userId);
      emit(
        state.copyWith(
          users: users,
          processingUserIds: processing,
          successMessage: successMessage,
        ),
      );
    } on AppFailure catch (failure) {
      final processing = {...state.processingUserIds}..remove(userId);
      emit(
        state.copyWith(
          processingUserIds: processing,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      final processing = {...state.processingUserIds}..remove(userId);
      emit(
        state.copyWith(
          processingUserIds: processing,
          errorMessage: 'تعذر تنفيذ الإجراء. حاول مرة أخرى.',
        ),
      );
    }
  }
}

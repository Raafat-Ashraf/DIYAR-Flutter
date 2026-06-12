part of 'account_cubit.dart';

enum AccountStatus { initial, loading, ready, submitting, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.profile,
    this.governorates = const [],
    this.specializations = const [],
    this.errorMessage,
    this.successMessage,
  });

  final AccountStatus status;
  final AccountProfile? profile;
  final List<Governorate> governorates;
  final List<Specialization> specializations;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == AccountStatus.loading;
  bool get isSubmitting => status == AccountStatus.submitting;
  bool get hasProfile => profile != null;

  AccountState copyWith({
    AccountStatus? status,
    AccountProfile? profile,
    List<Governorate>? governorates,
    List<Specialization>? specializations,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
    bool clearProfile = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      profile: clearProfile ? null : profile ?? this.profile,
      governorates: governorates ?? this.governorates,
      specializations: specializations ?? this.specializations,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    governorates,
    specializations,
    errorMessage,
    successMessage,
  ];
}

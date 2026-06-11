part of 'pending_verification_cubit.dart';

enum PendingVerificationStatus { initial, loading, loaded, failure }

class PendingVerificationState extends Equatable {
  const PendingVerificationState({
    this.status = PendingVerificationStatus.initial,
    this.users = const [],
    this.processingUserIds = const {},
    this.errorMessage,
    this.successMessage,
  });

  final PendingVerificationStatus status;
  final List<PendingUser> users;
  final Set<String> processingUserIds;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == PendingVerificationStatus.loading;
  bool get isEmpty =>
      status == PendingVerificationStatus.loaded && users.isEmpty;

  bool isProcessing(String userId) => processingUserIds.contains(userId);

  PendingVerificationState copyWith({
    PendingVerificationStatus? status,
    List<PendingUser>? users,
    Set<String>? processingUserIds,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PendingVerificationState(
      status: status ?? this.status,
      users: users ?? this.users,
      processingUserIds: processingUserIds ?? this.processingUserIds,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    processingUserIds,
    errorMessage,
    successMessage,
  ];
}

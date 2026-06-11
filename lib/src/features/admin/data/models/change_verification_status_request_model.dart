import '../../../account/domain/entities/account_profile.dart';

class ChangeVerificationStatusRequestModel {
  const ChangeVerificationStatusRequestModel({
    required this.status,
    this.rejectionReason,
  });

  final VerificationStatus status;
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
    'verificationStatus': _statusCode(status),
    'rejectionReason': rejectionReason,
  };

  static int _statusCode(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.notSubmitted => 0,
      VerificationStatus.pending => 1,
      VerificationStatus.approved => 2,
      VerificationStatus.rejected => 3,
    };
  }
}

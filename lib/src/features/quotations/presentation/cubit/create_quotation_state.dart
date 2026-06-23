import 'package:equatable/equatable.dart';

enum CreateQuotationStatus { initial, loading, success, error }

class CreateQuotationState extends Equatable {
  const CreateQuotationState({
    this.status = CreateQuotationStatus.initial,
    this.errorMessage,
  });

  final CreateQuotationStatus status;
  final String? errorMessage;

  CreateQuotationState copyWith({CreateQuotationStatus? status, String? errorMessage}) =>
      CreateQuotationState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, errorMessage];
}

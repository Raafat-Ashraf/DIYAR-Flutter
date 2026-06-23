import '../repositories/quotation_repository.dart';

class CancelQuotationUseCase {
  const CancelQuotationUseCase(this._repository);
  final QuotationRepository _repository;

  Future<void> call(int quotationId) => _repository.cancelQuotation(quotationId);
}

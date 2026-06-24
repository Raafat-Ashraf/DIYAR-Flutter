import '../repositories/quotation_repository.dart';

class RejectQuotationUseCase {
  const RejectQuotationUseCase(this._repository);
  final QuotationRepository _repository;

  Future<void> call(int quotationId) => _repository.rejectQuotation(quotationId);
}

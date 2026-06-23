import '../repositories/quotation_repository.dart';

class AcceptQuotationUseCase {
  const AcceptQuotationUseCase(this._repository);
  final QuotationRepository _repository;

  Future<void> call({required int requestId, required int quotationId}) =>
      _repository.acceptQuotation(requestId: requestId, quotationId: quotationId);
}

import '../entities/quotation.dart';

abstract class QuotationRepository {
  Future<PaginatedQuotations> getQuotations({
    required int pageNumber,
    required int pageSize,
    int? requestId,
    QuotationStatus? status,
    String? search,
    String? sortBy,
    bool? descending,
  });

  Future<Quotation> createQuotation(CreateQuotationInput input);

  Future<void> cancelQuotation(int quotationId);

  Future<void> acceptQuotation({required int requestId, required int quotationId});
}

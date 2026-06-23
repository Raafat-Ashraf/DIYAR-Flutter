import '../entities/quotation.dart';
import '../repositories/quotation_repository.dart';

class GetQuotationsUseCase {
  const GetQuotationsUseCase(this._repository);
  final QuotationRepository _repository;

  Future<PaginatedQuotations> call({
    required int pageNumber,
    required int pageSize,
    int? requestId,
    QuotationStatus? status,
    String? search,
    String? sortBy,
    bool? descending,
  }) =>
      _repository.getQuotations(
        pageNumber: pageNumber,
        pageSize: pageSize,
        requestId: requestId,
        status: status,
        search: search,
        sortBy: sortBy,
        descending: descending,
      );
}

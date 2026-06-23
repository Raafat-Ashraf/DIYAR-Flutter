import '../../domain/entities/quotation.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../datasources/quotation_remote_data_source.dart';

class QuotationRepositoryImpl implements QuotationRepository {
  const QuotationRepositoryImpl(this._dataSource);
  final QuotationRemoteDataSource _dataSource;

  @override
  Future<PaginatedQuotations> getQuotations({
    required int pageNumber,
    required int pageSize,
    int? requestId,
    QuotationStatus? status,
    String? search,
    String? sortBy,
    bool? descending,
  }) =>
      _dataSource.getQuotations(
        pageNumber: pageNumber,
        pageSize: pageSize,
        requestId: requestId,
        status: status,
        search: search,
        sortBy: sortBy,
        descending: descending,
      );

  @override
  Future<Quotation> createQuotation(CreateQuotationInput input) =>
      _dataSource.createQuotation(input);

  @override
  Future<void> cancelQuotation(int quotationId) =>
      _dataSource.cancelQuotation(quotationId);

  @override
  Future<void> acceptQuotation({required int requestId, required int quotationId}) =>
      _dataSource.acceptQuotation(requestId: requestId, quotationId: quotationId);
}

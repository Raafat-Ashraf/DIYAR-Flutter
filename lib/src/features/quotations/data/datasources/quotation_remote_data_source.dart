import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/entities/quotation_stats.dart';
import '../models/create_quotation_model.dart';

abstract class QuotationRemoteDataSource {
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
  Future<QuotationStats> getChartData();
  Future<void> rejectQuotation(int quotationId);
}

class QuotationRemoteDataSourceImpl implements QuotationRemoteDataSource {
  const QuotationRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedQuotations> getQuotations({
    required int pageNumber,
    required int pageSize,
    int? requestId,
    QuotationStatus? status,
    String? search,
    String? sortBy,
    bool? descending,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.getAllQuotations,
      queryParameters: {
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (requestId != null) 'RequestId': requestId,
        if (status != null) 'Status': status.apiValue,
        if (search != null && search.isNotEmpty) 'Search': search,
        if (sortBy != null) 'SortBy': sortBy,
        if (descending != null) 'Descending': descending,
      },
    );
    return PaginatedQuotations.fromJson(response);
  }

  @override
  Future<Quotation> createQuotation(CreateQuotationInput input) async {
    final formData = await CreateQuotationModel(input).toFormData();
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.createQuotation,
      data: formData,
    );
    return Quotation.fromJson(response);
  }

  @override
  Future<void> cancelQuotation(int quotationId) async {
    await _client.put<dynamic>('${ApiConstants.cancelQuotation}/$quotationId');
  }

  @override
  Future<void> acceptQuotation({required int requestId, required int quotationId}) async {
    await _client.post<dynamic>(
      ApiConstants.acceptQuotation,
      data: {'requestId': requestId, 'quotationId': quotationId},
    );
  }

  @override
  Future<QuotationStats> getChartData() async {
    final response = await _client.get<Map<String, dynamic>>(ApiConstants.quotationChartData);
    return QuotationStats.fromJson(response);
  }

  @override
  Future<void> rejectQuotation(int quotationId) async {
    await _client.put<dynamic>('${ApiConstants.rejectQuotation}/$quotationId');
  }
}

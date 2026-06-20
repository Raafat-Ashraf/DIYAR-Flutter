import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/request.dart';
import '../models/create_request_model.dart';

abstract class RequestRemoteDataSource {
  Future<PaginatedRequests> getRequests({
    required int pageNumber,
    required int pageSize,
    String? search,
    String? sortBy,
    bool? descending,
    RequestType? requestType,
    RequestStatus? status,
    String? clientId,
  });

  Future<RequestStats> getChartData();

  Future<RequestComment> addComment(AddCommentInput input);

  Future<void> createRequest(CreateRequestModel model);
}

class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  const RequestRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<PaginatedRequests> getRequests({
    required int pageNumber,
    required int pageSize,
    String? search,
    String? sortBy,
    bool? descending,
    RequestType? requestType,
    RequestStatus? status,
    String? clientId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.getAllRequests,
      queryParameters: {
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (search != null && search.isNotEmpty) 'Search': search,
        'SortBy': ?sortBy,
        'Descending': ?descending,
        if (requestType != null) 'RequestType': requestType.apiValue,
        if (status != null) 'Status': status.apiValue,
        if (clientId != null && clientId.isNotEmpty) 'ClientId': clientId,
      },
    );
    return PaginatedRequests.fromJson(response);
  }

  @override
  Future<RequestStats> getChartData() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.requestChartData,
    );
    return RequestStats.fromJson(response);
  }

  @override
  Future<RequestComment> addComment(AddCommentInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.addRequestComment,
      data: {
        'requestId': input.requestId,
        'content': input.content,
        if (input.parentCommentId != null)
          'parentCommentId': input.parentCommentId,
      },
    );
    return RequestComment.fromJson(response);
  }

  @override
  Future<void> createRequest(CreateRequestModel model) async {
    await _client.post<dynamic>(
      ApiConstants.createRequest,
      data: await model.toFormData(),
    );
  }
}

import '../entities/request.dart';

abstract class RequestRepository {
  Future<PaginatedRequests> getRequests({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    RequestType? requestType,
    RequestStatus? status,
    String? clientId,
  });

  Future<Request> getById(int id);

  Future<RequestStats> getChartData();

  Future<RequestComment> addComment(AddCommentInput input);

  Future<void> createRequest(CreateRequestInput input);
}

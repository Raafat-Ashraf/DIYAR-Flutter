import '../entities/request.dart';
import '../repositories/request_repository.dart';

class GetRequestsUseCase {
  const GetRequestsUseCase(this._repository);

  final RequestRepository _repository;

  Future<PaginatedRequests> call({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    RequestType? requestType,
    RequestStatus? status,
    String? clientId,
  }) {
    return _repository.getRequests(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      sortBy: sortBy,
      descending: descending,
      requestType: requestType,
      status: status,
      clientId: clientId,
    );
  }
}

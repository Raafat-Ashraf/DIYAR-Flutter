import '../../domain/entities/request.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_remote_data_source.dart';
import '../models/create_request_model.dart';

class RequestRepositoryImpl implements RequestRepository {
  const RequestRepositoryImpl(this._remoteDataSource);

  final RequestRemoteDataSource _remoteDataSource;

  @override
  Future<PaginatedRequests> getRequests({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    RequestType? requestType,
    RequestStatus? status,
    String? clientId,
  }) {
    return _remoteDataSource.getRequests(
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

  @override
  Future<Request> getById(int id) => _remoteDataSource.getById(id);

  @override
  Future<RequestStats> getChartData() => _remoteDataSource.getChartData();

  @override
  Future<RequestComment> addComment(AddCommentInput input) =>
      _remoteDataSource.addComment(input);

  @override
  Future<void> createRequest(CreateRequestInput input) {
    return _remoteDataSource.createRequest(CreateRequestModel(input));
  }
}

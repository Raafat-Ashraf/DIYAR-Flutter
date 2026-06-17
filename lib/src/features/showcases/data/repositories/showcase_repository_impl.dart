import '../../domain/entities/showcase.dart';
import '../../domain/repositories/showcase_repository.dart';
import '../datasources/showcase_remote_data_source.dart';
import '../models/create_showcase_request_model.dart';

class ShowcaseRepositoryImpl implements ShowcaseRepository {
  const ShowcaseRepositoryImpl(this._remoteDataSource);

  final ShowcaseRemoteDataSource _remoteDataSource;

  @override
  Future<void> createShowcase(CreateShowcaseInput input) {
    return _remoteDataSource.createShowcase(
      CreateShowcaseRequestModel(input),
    );
  }

  @override
  Future<PaginatedShowcases> getShowcases({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    ShowcaseType? type,
    bool? isOpen,
    String? userId,
  }) {
    return _remoteDataSource.getShowcases(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      sortBy: sortBy,
      descending: descending,
      type: type,
      isOpen: isOpen,
      userId: userId,
    );
  }
}

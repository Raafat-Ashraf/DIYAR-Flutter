import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/showcase.dart';
import '../models/create_showcase_request_model.dart';

abstract class ShowcaseRemoteDataSource {
  Future<void> createShowcase(CreateShowcaseRequestModel request);

  Future<PaginatedShowcases> getShowcases({
    required int pageNumber,
    required int pageSize,
    String? search,
    String? sortBy,
    bool? descending,
    ShowcaseType? type,
    bool? isOpen,
    String? userId,
  });
}

class ShowcaseRemoteDataSourceImpl implements ShowcaseRemoteDataSource {
  const ShowcaseRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> createShowcase(CreateShowcaseRequestModel request) async {
    await _client.post<dynamic>(
      ApiConstants.createShowcase,
      data: await request.toFormData(),
    );
  }

  @override
  Future<PaginatedShowcases> getShowcases({
    required int pageNumber,
    required int pageSize,
    String? search,
    String? sortBy,
    bool? descending,
    ShowcaseType? type,
    bool? isOpen,
    String? userId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.getAllShowcases,
      queryParameters: {
        'PageNumber': pageNumber,
        'PageSize': pageSize,
        if (search != null && search.isNotEmpty) 'Search': search,
        'SortBy': ?sortBy,
        'Descending': ?descending,
        if (type != null) 'Type': type.apiValue,
        'IsOpen': ?isOpen,
        if (userId != null && userId.isNotEmpty) 'UserId': userId,
      },
    );
    return PaginatedShowcases.fromJson(response);
  }
}

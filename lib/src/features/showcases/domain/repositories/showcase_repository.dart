import '../entities/showcase.dart';

abstract class ShowcaseRepository {
  Future<void> createShowcase(CreateShowcaseInput input);

  Future<PaginatedShowcases> getShowcases({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    ShowcaseType? type,
    bool? isOpen,
    String? userId,
  });
}

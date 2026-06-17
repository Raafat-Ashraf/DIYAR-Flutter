import '../entities/showcase.dart';
import '../repositories/showcase_repository.dart';

class GetShowcasesUseCase {
  const GetShowcasesUseCase(this._repository);

  final ShowcaseRepository _repository;

  Future<PaginatedShowcases> call({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? descending,
    ShowcaseType? type,
    bool? isOpen,
    String? userId,
  }) {
    return _repository.getShowcases(
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

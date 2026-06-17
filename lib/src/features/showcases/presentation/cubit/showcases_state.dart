part of 'showcases_cubit.dart';

enum ShowcasesStatus { initial, loading, loaded, loadingMore, failure }

class ShowcasesState extends Equatable {
  const ShowcasesState({
    this.status = ShowcasesStatus.initial,
    this.items = const [],
    this.pageNumber = 1,
    this.totalPages = 1,
    this.search = '',
    this.sort = ShowcaseSortOption.newest,
    this.type,
    this.errorMessage,
  });

  final ShowcasesStatus status;
  final List<Showcase> items;
  final int pageNumber;
  final int totalPages;
  final String search;
  final ShowcaseSortOption sort;
  final ShowcaseType? type;
  final String? errorMessage;

  bool get isLoading => status == ShowcasesStatus.loading;
  bool get isLoadingMore => status == ShowcasesStatus.loadingMore;
  bool get hasMore => pageNumber < totalPages;

  ShowcasesState copyWith({
    ShowcasesStatus? status,
    List<Showcase>? items,
    int? pageNumber,
    int? totalPages,
    String? search,
    ShowcaseSortOption? sort,
    ShowcaseType? type,
    bool clearType = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShowcasesState(
      status: status ?? this.status,
      items: items ?? this.items,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      type: clearType ? null : (type ?? this.type),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    pageNumber,
    totalPages,
    search,
    sort,
    type,
    errorMessage,
  ];
}

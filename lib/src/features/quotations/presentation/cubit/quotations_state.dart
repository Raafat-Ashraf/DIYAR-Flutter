import 'package:equatable/equatable.dart';

import '../../domain/entities/quotation.dart';

enum QuotationsStatus { initial, loading, loaded, loadingMore, failure }

class QuotationsState extends Equatable {
  const QuotationsState({
    this.status = QuotationsStatus.initial,
    this.items = const [],
    this.pageNumber = 1,
    this.totalPages = 1,
    this.search = '',
    this.sort = QuotationSortOption.newest,
    this.filterStatus,
    this.errorMessage,
    this.actionError,
  });

  final QuotationsStatus status;
  final List<Quotation> items;
  final int pageNumber;
  final int totalPages;
  final String search;
  final QuotationSortOption sort;
  final QuotationStatus? filterStatus;
  final String? errorMessage;
  final String? actionError;

  bool get isLoading => status == QuotationsStatus.loading;
  bool get isLoadingMore => status == QuotationsStatus.loadingMore;
  bool get hasMore => pageNumber < totalPages;

  QuotationsState copyWith({
    QuotationsStatus? status,
    List<Quotation>? items,
    int? pageNumber,
    int? totalPages,
    String? search,
    QuotationSortOption? sort,
    QuotationStatus? filterStatus,
    bool clearFilterStatus = false,
    String? errorMessage,
    bool clearError = false,
    String? actionError,
  }) {
    return QuotationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      filterStatus: clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
    status, items, pageNumber, totalPages, search, sort,
    filterStatus, errorMessage, actionError,
  ];
}

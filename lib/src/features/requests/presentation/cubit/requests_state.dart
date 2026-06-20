part of 'requests_cubit.dart';

enum RequestsStatus { initial, loading, loaded, loadingMore, failure }

class RequestsState extends Equatable {
  const RequestsState({
    this.status = RequestsStatus.initial,
    this.items = const [],
    this.pageNumber = 1,
    this.totalPages = 1,
    this.search = '',
    this.sort = RequestSortOption.newest,
    this.requestType,
    this.requestStatus,
    this.errorMessage,
  });

  final RequestsStatus status;
  final List<Request> items;
  final int pageNumber;
  final int totalPages;
  final String search;
  final RequestSortOption sort;
  final RequestType? requestType;
  final RequestStatus? requestStatus;
  final String? errorMessage;

  bool get isLoading => status == RequestsStatus.loading;
  bool get isLoadingMore => status == RequestsStatus.loadingMore;
  bool get hasMore => pageNumber < totalPages;

  RequestsState copyWith({
    RequestsStatus? status,
    List<Request>? items,
    int? pageNumber,
    int? totalPages,
    String? search,
    RequestSortOption? sort,
    RequestType? requestType,
    bool clearRequestType = false,
    RequestStatus? requestStatus,
    bool clearRequestStatus = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RequestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      requestType: clearRequestType ? null : (requestType ?? this.requestType),
      requestStatus: clearRequestStatus ? null : (requestStatus ?? this.requestStatus),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status, items, pageNumber, totalPages, search, sort,
    requestType, requestStatus, errorMessage,
  ];
}

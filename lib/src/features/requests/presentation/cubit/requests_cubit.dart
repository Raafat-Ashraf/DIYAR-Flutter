import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/request.dart';
import '../../domain/usecases/get_requests_use_case.dart';

part 'requests_state.dart';

class RequestsCubit extends Cubit<RequestsState> {
  RequestsCubit({
    required this.getRequests,
    this.clientId,
    this.pageSize = 10,
  }) : super(const RequestsState());

  final GetRequestsUseCase getRequests;
  final String? clientId;
  final int pageSize;

  Timer? _searchDebounce;

  Future<void> load() async {
    emit(state.copyWith(status: RequestsStatus.loading, clearError: true));
    await _fetch(pageNumber: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(status: RequestsStatus.loadingMore));
    await _fetch(pageNumber: state.pageNumber + 1, replace: false);
  }

  void search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (value == state.search) return;
      emit(state.copyWith(search: value));
      load();
    });
  }

  void changeSort(RequestSortOption sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    load();
  }

  void changeRequestType(RequestType? type) {
    if (type == state.requestType) return;
    emit(state.copyWith(requestType: type, clearRequestType: type == null));
    load();
  }

  void changeStatus(RequestStatus? status) {
    if (status == state.requestStatus) return;
    emit(state.copyWith(requestStatus: status, clearRequestStatus: status == null));
    load();
  }

  Future<void> _fetch({required int pageNumber, required bool replace}) async {
    try {
      final result = await getRequests(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: state.search.isEmpty ? null : state.search,
        sortBy: state.sort.sortBy,
        descending: state.sort.descending,
        requestType: state.requestType,
        status: state.requestStatus,
        clientId: clientId,
      );
      final items = replace ? result.items : [...state.items, ...result.items];
      emit(
        state.copyWith(
          status: RequestsStatus.loaded,
          items: items,
          pageNumber: result.pageNumber,
          totalPages: result.totalPages,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: RequestsStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestsStatus.failure,
          errorMessage: 'تعذر تحميل الطلبات.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

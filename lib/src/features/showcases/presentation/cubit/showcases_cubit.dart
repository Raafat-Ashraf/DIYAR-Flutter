import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/showcase.dart';
import '../../domain/usecases/get_showcases_use_case.dart';

part 'showcases_state.dart';

class ShowcasesCubit extends Cubit<ShowcasesState> {
  ShowcasesCubit({
    required this.getShowcases,
    this.userId,
    this.pageSize = 10,
  }) : super(const ShowcasesState());

  final GetShowcasesUseCase getShowcases;
  final String? userId;
  final int pageSize;

  Timer? _searchDebounce;

  Future<void> load() async {
    emit(state.copyWith(status: ShowcasesStatus.loading, clearError: true));
    await _fetch(pageNumber: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(status: ShowcasesStatus.loadingMore));
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

  void changeSort(ShowcaseSortOption sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    load();
  }

  void changeType(ShowcaseType? type) {
    if (type == state.type) return;
    emit(state.copyWith(type: type, clearType: type == null));
    load();
  }

  Future<void> _fetch({required int pageNumber, required bool replace}) async {
    try {
      final result = await getShowcases(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: state.search.isEmpty ? null : state.search,
        sortBy: state.sort.sortBy,
        descending: state.sort.descending,
        type: state.type,
        userId: userId,
      );
      final items = replace
          ? result.items
          : [...state.items, ...result.items];
      emit(
        state.copyWith(
          status: ShowcasesStatus.loaded,
          items: items,
          pageNumber: result.pageNumber,
          totalPages: result.totalPages,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: ShowcasesStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ShowcasesStatus.failure,
          errorMessage: 'تعذر تحميل العروض.',
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

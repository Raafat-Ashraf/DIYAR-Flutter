import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/usecases/accept_quotation_use_case.dart';
import '../../domain/usecases/cancel_quotation_use_case.dart';
import '../../domain/usecases/get_quotations_use_case.dart';
import '../../domain/usecases/reject_quotation_use_case.dart';
import 'quotations_state.dart';

class QuotationsCubit extends Cubit<QuotationsState> {
  QuotationsCubit({
    required GetQuotationsUseCase getQuotations,
    required CancelQuotationUseCase cancelQuotation,
    required AcceptQuotationUseCase acceptQuotation,
    required RejectQuotationUseCase rejectQuotation,
    this.requestId,
    this.pageSize = 10,
  })  : _getQuotations = getQuotations,
        _cancelQuotation = cancelQuotation,
        _acceptQuotation = acceptQuotation,
        _rejectQuotation = rejectQuotation,
        super(const QuotationsState());

  // ignore: prefer_initializing_formals
  final GetQuotationsUseCase _getQuotations;
  // ignore: prefer_initializing_formals
  final CancelQuotationUseCase _cancelQuotation;
  // ignore: prefer_initializing_formals
  final AcceptQuotationUseCase _acceptQuotation;
  // ignore: prefer_initializing_formals
  final RejectQuotationUseCase _rejectQuotation;

  final int? requestId;
  final int pageSize;

  Timer? _searchDebounce;

  Future<void> load() async {
    emit(state.copyWith(status: QuotationsStatus.loading, clearError: true));
    await _fetch(pageNumber: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(status: QuotationsStatus.loadingMore));
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

  void changeSort(QuotationSortOption sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    load();
  }

  void changeStatus(QuotationStatus? status) {
    if (status == state.filterStatus) return;
    emit(state.copyWith(filterStatus: status, clearFilterStatus: status == null));
    load();
  }

  Future<bool> cancelQuotation(int quotationId) async {
    try {
      await _cancelQuotation(quotationId);
      final updated = state.items
          .map((q) => q.id == quotationId
              ? Quotation(
                  id: q.id,
                  requestId: q.requestId,
                  provider: q.provider,
                  price: q.price,
                  executionDurationDays: q.executionDurationDays,
                  description: q.description,
                  status: QuotationStatus.cancelled,
                  isContactRevealed: q.isContactRevealed,
                  createdAt: q.createdAt,
                  attachments: q.attachments,
                )
              : q)
          .toList();
      emit(state.copyWith(items: updated));
      return true;
    } on AppFailure catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(actionError: 'حدث خطأ غير متوقع'));
      return false;
    }
  }

  Future<bool> rejectQuotation(int quotationId) async {
    try {
      await _rejectQuotation(quotationId);
      final updated = state.items
          .map((q) => q.id == quotationId
              ? Quotation(
                  id: q.id, requestId: q.requestId, provider: q.provider,
                  price: q.price, executionDurationDays: q.executionDurationDays,
                  description: q.description, status: QuotationStatus.rejected,
                  isContactRevealed: q.isContactRevealed, createdAt: q.createdAt,
                  attachments: q.attachments)
              : q)
          .toList();
      emit(state.copyWith(items: updated));
      return true;
    } on AppFailure catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(actionError: 'حدث خطأ غير متوقع'));
      return false;
    }
  }

  Future<bool> acceptQuotation({required int requestId, required int quotationId}) async {
    try {
      await _acceptQuotation(requestId: requestId, quotationId: quotationId);
      await load();
      return true;
    } on AppFailure catch (e) {
      emit(state.copyWith(actionError: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(actionError: 'حدث خطأ غير متوقع'));
      return false;
    }
  }

  Future<void> _fetch({required int pageNumber, required bool replace}) async {
    try {
      final result = await _getQuotations(
        pageNumber: pageNumber,
        pageSize: pageSize,
        requestId: requestId,
        status: state.filterStatus,
        search: state.search.isEmpty ? null : state.search,
        sortBy: state.sort.sortBy,
        descending: state.sort.descending,
      );
      final items = replace ? result.items : [...state.items, ...result.items];
      emit(state.copyWith(
        status: QuotationsStatus.loaded,
        items: items,
        pageNumber: result.pageNumber,
        totalPages: result.totalPages,
      ));
    } on AppFailure catch (e) {
      emit(state.copyWith(status: QuotationsStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(status: QuotationsStatus.failure, errorMessage: 'تعذر تحميل العروض'));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

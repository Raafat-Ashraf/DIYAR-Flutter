import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/quotation_remote_data_source.dart';
import '../../domain/entities/quotation_stats.dart';

class QuotationStatsCubit extends Cubit<QuotationStatsState> {
  QuotationStatsCubit(this._dataSource) : super(const QuotationStatsState());

  final QuotationRemoteDataSource _dataSource;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final stats = await _dataSource.getChartData();
      emit(state.copyWith(isLoading: false, stats: stats));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }
}

class QuotationStatsState {
  const QuotationStatsState({this.isLoading = false, this.stats});
  final bool isLoading;
  final QuotationStats? stats;

  QuotationStatsState copyWith({bool? isLoading, QuotationStats? stats}) =>
      QuotationStatsState(
        isLoading: isLoading ?? this.isLoading,
        stats: stats ?? this.stats,
      );
}

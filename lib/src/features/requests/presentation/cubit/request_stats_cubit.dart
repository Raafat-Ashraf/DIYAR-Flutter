import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/request.dart';
import '../../domain/usecases/get_request_chart_data_use_case.dart';

part 'request_stats_state.dart';

class RequestStatsCubit extends Cubit<RequestStatsState> {
  RequestStatsCubit({required this.getChartData})
      : super(const RequestStatsState());

  final GetRequestChartDataUseCase getChartData;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final stats = await getChartData();
      emit(state.copyWith(isLoading: false, stats: stats));
    } on AppFailure catch (f) {
      emit(state.copyWith(isLoading: false, errorMessage: f.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'تعذر تحميل الإحصائيات.'));
    }
  }
}

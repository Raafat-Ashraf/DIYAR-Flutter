part of 'request_stats_cubit.dart';

class RequestStatsState extends Equatable {
  const RequestStatsState({
    this.isLoading = false,
    this.stats,
    this.errorMessage,
  });

  final bool isLoading;
  final RequestStats? stats;
  final String? errorMessage;

  RequestStatsState copyWith({
    bool? isLoading,
    RequestStats? stats,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RequestStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, errorMessage];
}

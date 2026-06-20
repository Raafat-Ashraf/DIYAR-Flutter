import '../entities/request.dart';
import '../repositories/request_repository.dart';

class GetRequestChartDataUseCase {
  const GetRequestChartDataUseCase(this._repository);

  final RequestRepository _repository;

  Future<RequestStats> call() => _repository.getChartData();
}

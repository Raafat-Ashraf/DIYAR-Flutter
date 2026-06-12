import '../entities/specialization.dart';
import '../repositories/specialization_repository.dart';

class GetMeasurementUnitsUseCase {
  const GetMeasurementUnitsUseCase(this._repository);

  final SpecializationRepository _repository;

  Future<List<MeasurementUnit>> call() => _repository.getAllMeasurementUnits();
}

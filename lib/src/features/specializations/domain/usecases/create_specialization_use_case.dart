import '../entities/specialization.dart';
import '../repositories/specialization_repository.dart';

class CreateSpecializationUseCase {
  const CreateSpecializationUseCase(this._repository);

  final SpecializationRepository _repository;

  Future<void> call({
    required String name,
    required SpecializationType type,
    required int measurementUnitId,
    int? parentSpecializationId,
  }) {
    return _repository.create(
      name: name,
      type: type,
      measurementUnitId: measurementUnitId,
      parentSpecializationId: parentSpecializationId,
    );
  }
}

import '../repositories/specialization_repository.dart';

class UpdateSpecializationUseCase {
  const UpdateSpecializationUseCase(this._repository);

  final SpecializationRepository _repository;

  Future<void> call({
    required int id,
    required String name,
    required int measurementUnitId,
  }) {
    return _repository.update(
      id: id,
      name: name,
      measurementUnitId: measurementUnitId,
    );
  }
}

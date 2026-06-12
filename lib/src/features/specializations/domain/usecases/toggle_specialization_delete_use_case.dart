import '../repositories/specialization_repository.dart';

class ToggleSpecializationDeleteUseCase {
  const ToggleSpecializationDeleteUseCase(this._repository);

  final SpecializationRepository _repository;

  Future<void> call(int id) {
    return _repository.toggleDelete(id);
  }
}

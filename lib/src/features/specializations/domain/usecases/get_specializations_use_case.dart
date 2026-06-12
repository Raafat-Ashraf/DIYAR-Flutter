import '../entities/specialization.dart';
import '../repositories/specialization_repository.dart';

class GetSpecializationsUseCase {
  const GetSpecializationsUseCase(this._repository);

  final SpecializationRepository _repository;

  Future<List<Specialization>> call(SpecializationType type) {
    return _repository.getAll(type);
  }
}

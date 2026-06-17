import '../entities/showcase.dart';
import '../repositories/showcase_repository.dart';

class CreateShowcaseUseCase {
  const CreateShowcaseUseCase(this._repository);

  final ShowcaseRepository _repository;

  Future<void> call(CreateShowcaseInput input) {
    return _repository.createShowcase(input);
  }
}

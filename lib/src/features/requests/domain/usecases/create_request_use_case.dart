import '../entities/request.dart';
import '../repositories/request_repository.dart';

class CreateRequestUseCase {
  const CreateRequestUseCase(this._repository);

  final RequestRepository _repository;

  Future<void> call(CreateRequestInput input) => _repository.createRequest(input);
}

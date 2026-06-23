import '../entities/request.dart';
import '../repositories/request_repository.dart';

class GetRequestByIdUseCase {
  const GetRequestByIdUseCase(this._repository);
  final RequestRepository _repository;

  Future<Request> call(int id) => _repository.getById(id);
}

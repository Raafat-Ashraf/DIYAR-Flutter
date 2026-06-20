import '../entities/request.dart';
import '../repositories/request_repository.dart';

class AddCommentUseCase {
  const AddCommentUseCase(this._repository);

  final RequestRepository _repository;

  Future<RequestComment> call(AddCommentInput input) =>
      _repository.addComment(input);
}

import '../entities/quotation.dart';
import '../repositories/quotation_repository.dart';

class CreateQuotationUseCase {
  const CreateQuotationUseCase(this._repository);
  final QuotationRepository _repository;

  Future<Quotation> call(CreateQuotationInput input) =>
      _repository.createQuotation(input);
}

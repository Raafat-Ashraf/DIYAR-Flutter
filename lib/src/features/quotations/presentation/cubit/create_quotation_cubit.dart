import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/usecases/create_quotation_use_case.dart';
import 'create_quotation_state.dart';

class CreateQuotationCubit extends Cubit<CreateQuotationState> {
  CreateQuotationCubit({required CreateQuotationUseCase createQuotation})
      : _createQuotation = createQuotation,
        super(const CreateQuotationState());

  // ignore: prefer_initializing_formals
  final CreateQuotationUseCase _createQuotation;

  Future<bool> submit(CreateQuotationInput input) async {
    emit(state.copyWith(status: CreateQuotationStatus.loading));
    try {
      await _createQuotation(input);
      emit(state.copyWith(status: CreateQuotationStatus.success));
      return true;
    } on AppFailure catch (e) {
      emit(state.copyWith(status: CreateQuotationStatus.error, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(state.copyWith(status: CreateQuotationStatus.error, errorMessage: 'حدث خطأ غير متوقع'));
      return false;
    }
  }
}

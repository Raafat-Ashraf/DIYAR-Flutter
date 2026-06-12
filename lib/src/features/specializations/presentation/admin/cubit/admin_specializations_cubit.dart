import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/app_failure.dart';
import '../../../domain/entities/specialization.dart';
import '../../../domain/usecases/create_specialization_use_case.dart';
import '../../../domain/usecases/get_measurement_units_use_case.dart';
import '../../../domain/usecases/get_specializations_use_case.dart';
import '../../../domain/usecases/toggle_specialization_delete_use_case.dart';
import '../../../domain/usecases/update_specialization_use_case.dart';

part 'admin_specializations_state.dart';

class AdminSpecializationsCubit extends Cubit<AdminSpecializationsState> {
  AdminSpecializationsCubit({
    required this.getSpecializations,
    required this.getMeasurementUnits,
    required this.createSpecialization,
    required this.updateSpecialization,
    required this.toggleSpecializationDelete,
  }) : super(const AdminSpecializationsState());

  final GetSpecializationsUseCase getSpecializations;
  final GetMeasurementUnitsUseCase getMeasurementUnits;
  final CreateSpecializationUseCase createSpecialization;
  final UpdateSpecializationUseCase updateSpecialization;
  final ToggleSpecializationDeleteUseCase toggleSpecializationDelete;

  Future<void> load() async {
    emit(state.copyWith(status: AdminSpecializationsStatus.loading, clearMessages: true));
    try {
      final results = await Future.wait<Object>([
        getSpecializations(SpecializationType.product),
        getSpecializations(SpecializationType.engineeringService),
        getMeasurementUnits(),
      ]);
      emit(
        state.copyWith(
          status: AdminSpecializationsStatus.loaded,
          productRoots: results[0] as List<Specialization>,
          engineeringRoots: results[1] as List<Specialization>,
          measurementUnits: results[2] as List<MeasurementUnit>,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: AdminSpecializationsStatus.failure,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminSpecializationsStatus.failure,
          errorMessage: 'تعذر تحميل التخصصات.',
        ),
      );
    }
  }

  void selectType(SpecializationType type) {
    if (state.selectedType == type) return;
    emit(state.copyWith(selectedType: type, path: const [], clearMessages: true));
  }

  void drillInto(Specialization node) {
    emit(state.copyWith(path: [...state.path, node.id], clearMessages: true));
  }

  void goBack() {
    if (state.path.isEmpty) return;
    emit(
      state.copyWith(
        path: state.path.sublist(0, state.path.length - 1),
        clearMessages: true,
      ),
    );
  }

  Future<void> createNode({
    required String name,
    required int measurementUnitId,
  }) async {
    emit(state.copyWith(isMutating: true, clearMessages: true));
    try {
      await createSpecialization(
        name: name,
        type: state.selectedType,
        measurementUnitId: measurementUnitId,
        parentSpecializationId: state.currentParent?.id,
      );
      await _reloadCurrentType(successMessage: 'تمت إضافة التخصص بنجاح.');
    } on AppFailure catch (failure) {
      emit(state.copyWith(isMutating: false, errorMessage: failure.message));
    } catch (_) {
      emit(
        state.copyWith(
          isMutating: false,
          errorMessage: 'تعذر إضافة التخصص. حاول مرة أخرى.',
        ),
      );
    }
  }

  Future<void> updateNode(
    Specialization node, {
    required String name,
    required int measurementUnitId,
  }) async {
    emit(
      state.copyWith(
        processingIds: {...state.processingIds, node.id},
        clearMessages: true,
      ),
    );
    try {
      await updateSpecialization(
        id: node.id,
        name: name,
        measurementUnitId: measurementUnitId,
      );
      await _reloadCurrentType(successMessage: 'تم تحديث التخصص بنجاح.');
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          processingIds: _withoutId(node.id),
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          processingIds: _withoutId(node.id),
          errorMessage: 'تعذر تحديث التخصص. حاول مرة أخرى.',
        ),
      );
    }
  }

  Future<void> toggleDelete(Specialization node) async {
    emit(
      state.copyWith(
        processingIds: {...state.processingIds, node.id},
        clearMessages: true,
      ),
    );
    try {
      await toggleSpecializationDelete(node.id);
      final message = node.isDeleted
          ? 'تمت استعادة التخصص بنجاح.'
          : 'تم حذف التخصص بنجاح.';
      await _reloadCurrentType(successMessage: message);
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          processingIds: _withoutId(node.id),
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          processingIds: _withoutId(node.id),
          errorMessage: 'تعذر تنفيذ الإجراء. حاول مرة أخرى.',
        ),
      );
    }
  }

  Set<int> _withoutId(int id) => {...state.processingIds}..remove(id);

  Future<void> _reloadCurrentType({String? successMessage}) async {
    final items = await getSpecializations(state.selectedType);
    emit(
      state.selectedType == SpecializationType.product
          ? state.copyWith(
              productRoots: items,
              processingIds: const {},
              isMutating: false,
              successMessage: successMessage,
            )
          : state.copyWith(
              engineeringRoots: items,
              processingIds: const {},
              isMutating: false,
              successMessage: successMessage,
            ),
    );
  }
}

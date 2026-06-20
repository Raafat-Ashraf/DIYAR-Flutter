import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/domain/usecases/get_governorate_cities_use_case.dart';
import '../../../account/domain/usecases/get_governorates_use_case.dart';
import '../../../specializations/domain/entities/specialization.dart';
import '../../../specializations/domain/usecases/get_specializations_use_case.dart';
import '../../domain/entities/request.dart';
import '../../domain/usecases/create_request_use_case.dart';

part 'create_request_state.dart';

class CreateRequestCubit extends Cubit<CreateRequestState> {
  CreateRequestCubit({
    required this.createRequest,
    required this.getSpecializations,
    required this.getGovernorates,
    required this.getGovernorateCities,
  }) : super(const CreateRequestState());

  final CreateRequestUseCase createRequest;
  final GetSpecializationsUseCase getSpecializations;
  final GetGovernoratesUseCase getGovernorates;
  final GetGovernorateCitiesUseCase getGovernorateCities;

  static const _picker = NativeDocumentPicker();
  static const _maxFileSize = 10 * 1024 * 1024;
  static const _allowedMimeTypes = {
    'image/jpeg', 'image/png',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };
  static const _allowedExtensions = {
    '.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx', '.xls', '.xlsx',
  };

  void selectRequestType(RequestType type) {
    emit(state.copyWith(
      requestType: type,
      clearSpecialization: true,
      specializations: [],
    ));
  }

  Future<void> goToStep(int step) async {
    if (step == 1 && state.specializations.isEmpty) {
      await _loadSpecializations();
    } else if (step == 2 && state.governorates.isEmpty) {
      await _loadGovernorates();
    } else {
      emit(state.copyWith(step: step, clearError: true));
    }
  }

  Future<void> _loadSpecializations() async {
    final type = state.requestType;
    if (type == null) return;
    emit(state.copyWith(
      status: CreateRequestStatus.loadingSpecializations,
      clearError: true,
    ));
    try {
      final specs = await getSpecializations(
        SpecializationType.fromApi(type.specializationTypeApiValue)!,
      );
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        step: 1,
        specializations: specs,
      ));
    } on AppFailure catch (f) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: f.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: 'تعذر تحميل التخصصات.',
      ));
    }
  }

  Future<void> _loadGovernorates() async {
    emit(state.copyWith(
      status: CreateRequestStatus.loadingGovernorates,
      clearError: true,
    ));
    try {
      final govs = await getGovernorates();
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        step: 2,
        governorates: govs,
      ));
    } on AppFailure catch (f) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: f.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: 'تعذر تحميل المحافظات.',
      ));
    }
  }

  void selectSpecialization(Specialization spec) {
    emit(state.copyWith(selectedSpecialization: spec, clearError: true));
  }

  Future<void> selectGovernorate(Governorate gov) async {
    emit(state.copyWith(
      selectedGovernorate: gov,
      clearCity: true,
      cities: [],
      status: CreateRequestStatus.loadingCities,
      clearError: true,
    ));
    try {
      final result = await getGovernorateCities(gov.id);
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        cities: result.cities,
      ));
    } on AppFailure catch (f) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: f.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: 'تعذر تحميل المدن.',
      ));
    }
  }

  void selectCity(City city) {
    emit(state.copyWith(selectedCity: city, clearError: true));
  }

  Future<void> pickFiles() async {
    if (state.files.length >= 10) {
      emit(state.copyWith(errorMessage: 'الحد الأقصى 10 ملفات.'));
      return;
    }
    try {
      final picked = await _picker.pickMultipleDocuments();
      if (picked.isEmpty) return;

      final valid = picked.where(_isFileValid).map(
        (doc) => PickedRequestFile(document: doc),
      ).toList();

      final remaining = 10 - state.files.length;
      final accepted = valid.take(remaining).toList();
      final files = [...state.files, ...accepted];

      if (accepted.length < picked.length) {
        emit(state.copyWith(
          files: files,
          errorMessage:
              'تم تجاهل بعض الملفات (JPG، PNG، PDF، DOC، XLS فقط، وحتى 10 ميجابايت).',
        ));
        return;
      }
      emit(state.copyWith(files: files, clearError: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'تعذر اختيار الملفات.'));
    }
  }

  void removeFile(int index) {
    final files = [...state.files]..removeAt(index);
    emit(state.copyWith(files: files));
  }

  void updateFileDescription(int index, String description) {
    final files = [...state.files];
    files[index] = files[index].copyWith(description: description);
    emit(state.copyWith(files: files));
  }

  Future<void> submit({
    required String address,
    double? quantity,
    double? expectedBudget,
    int? executionDurationDays,
    String? description,
  }) async {
    final requestType = state.requestType;
    final spec = state.selectedSpecialization;
    final city = state.selectedCity;

    if (requestType == null || spec == null || city == null) return;

    emit(state.copyWith(status: CreateRequestStatus.submitting, clearError: true));
    try {
      await createRequest(
        CreateRequestInput(
          requestType: requestType,
          specializationId: spec.id,
          cityId: city.id,
          address: address,
          quantity: quantity,
          expectedBudget: expectedBudget,
          executionDurationDays: executionDurationDays,
          description: description,
          files: state.files.map(
            (f) => RequestLocalFile(
              path: f.document.path,
              name: f.document.name,
              contentType: f.document.contentType,
              description: f.description.isEmpty ? null : f.description,
            ),
          ).toList(),
        ),
      );
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        isSuccess: true,
      ));
    } on AppFailure catch (failure) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: CreateRequestStatus.initial,
        errorMessage: 'تعذر إنشاء الطلب. حاول مرة أخرى.',
      ));
    }
  }

  bool _isFileValid(PickedNativeDocument doc) {
    if (doc.size > _maxFileSize) return false;
    if (_allowedMimeTypes.contains(doc.contentType)) return true;
    final lower = doc.name.toLowerCase();
    return _allowedExtensions.any((ext) => lower.endsWith(ext));
  }
}

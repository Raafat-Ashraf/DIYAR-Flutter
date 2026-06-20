part of 'create_request_cubit.dart';

enum CreateRequestStatus {
  initial,
  loadingSpecializations,
  loadingGovernorates,
  loadingCities,
  submitting,
}

class PickedRequestFile extends Equatable {
  const PickedRequestFile({required this.document, this.description = ''});

  final PickedNativeDocument document;
  final String description;

  PickedRequestFile copyWith({String? description}) {
    return PickedRequestFile(
      document: document,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [document, description];
}

class CreateRequestState extends Equatable {
  const CreateRequestState({
    this.step = 0,
    this.status = CreateRequestStatus.initial,
    this.requestType,
    this.specializations = const [],
    this.selectedSpecialization,
    this.governorates = const [],
    this.selectedGovernorate,
    this.cities = const [],
    this.selectedCity,
    this.files = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  final int step;
  final CreateRequestStatus status;
  final RequestType? requestType;
  final List<Specialization> specializations;
  final Specialization? selectedSpecialization;
  final List<Governorate> governorates;
  final Governorate? selectedGovernorate;
  final List<City> cities;
  final City? selectedCity;
  final List<PickedRequestFile> files;
  final String? errorMessage;
  final bool isSuccess;

  bool get isLoading =>
      status == CreateRequestStatus.loadingSpecializations ||
      status == CreateRequestStatus.loadingGovernorates ||
      status == CreateRequestStatus.loadingCities;
  bool get isSubmitting => status == CreateRequestStatus.submitting;

  CreateRequestState copyWith({
    int? step,
    CreateRequestStatus? status,
    RequestType? requestType,
    List<Specialization>? specializations,
    Specialization? selectedSpecialization,
    bool clearSpecialization = false,
    List<Governorate>? governorates,
    Governorate? selectedGovernorate,
    bool clearGovernorate = false,
    List<City>? cities,
    City? selectedCity,
    bool clearCity = false,
    List<PickedRequestFile>? files,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return CreateRequestState(
      step: step ?? this.step,
      status: status ?? this.status,
      requestType: requestType ?? this.requestType,
      specializations: specializations ?? this.specializations,
      selectedSpecialization: clearSpecialization
          ? null
          : (selectedSpecialization ?? this.selectedSpecialization),
      governorates: governorates ?? this.governorates,
      selectedGovernorate: clearGovernorate
          ? null
          : (selectedGovernorate ?? this.selectedGovernorate),
      cities: cities ?? this.cities,
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      files: files ?? this.files,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
    step, status, requestType, specializations, selectedSpecialization,
    governorates, selectedGovernorate, cities, selectedCity,
    files, errorMessage, isSuccess,
  ];
}

import '../../domain/entities/specialization.dart';

class CreateSpecializationRequestModel {
  const CreateSpecializationRequestModel({
    required this.name,
    required this.type,
    required this.measurementUnitId,
    this.parentSpecializationId,
  });

  final String name;
  final SpecializationType type;
  final int measurementUnitId;
  final int? parentSpecializationId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.apiValue,
    'measurementUnitId': measurementUnitId,
    'parentSpecializationId': parentSpecializationId,
  };
}

class UpdateSpecializationRequestModel {
  const UpdateSpecializationRequestModel({
    required this.name,
    required this.measurementUnitId,
  });

  final String name;
  final int measurementUnitId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'measurementUnitId': measurementUnitId,
  };
}

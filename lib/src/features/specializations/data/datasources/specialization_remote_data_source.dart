import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/specialization.dart';
import '../models/specialization_request_models.dart';

abstract class SpecializationRemoteDataSource {
  Future<List<Specialization>> getAll(SpecializationType type);

  Future<List<MeasurementUnit>> getAllMeasurementUnits();

  Future<void> create(CreateSpecializationRequestModel request);

  Future<void> update(int id, UpdateSpecializationRequestModel request);

  Future<void> toggleDelete(int id);
}

class SpecializationRemoteDataSourceImpl implements SpecializationRemoteDataSource {
  const SpecializationRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<Specialization>> getAll(SpecializationType type) async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.getAllSpecializations,
      queryParameters: {'type': type.apiValue},
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(Specialization.fromJson)
        .toList();
  }

  @override
  Future<List<MeasurementUnit>> getAllMeasurementUnits() async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.getAllMeasurementUnits,
    );
    return response
        .whereType<Map<String, dynamic>>()
        .map(MeasurementUnit.fromJson)
        .toList();
  }

  @override
  Future<void> create(CreateSpecializationRequestModel request) async {
    await _client.post<dynamic>(
      ApiConstants.createSpecialization,
      data: request.toJson(),
    );
  }

  @override
  Future<void> update(int id, UpdateSpecializationRequestModel request) async {
    await _client.put<dynamic>(
      '${ApiConstants.updateSpecialization}/$id',
      data: request.toJson(),
    );
  }

  @override
  Future<void> toggleDelete(int id) async {
    await _client.put<dynamic>('${ApiConstants.toggleDeleteSpecialization}/$id');
  }
}

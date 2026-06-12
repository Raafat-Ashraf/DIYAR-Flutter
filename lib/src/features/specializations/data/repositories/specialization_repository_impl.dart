import '../../domain/entities/specialization.dart';
import '../../domain/repositories/specialization_repository.dart';
import '../datasources/specialization_remote_data_source.dart';
import '../models/specialization_request_models.dart';

class SpecializationRepositoryImpl implements SpecializationRepository {
  const SpecializationRepositoryImpl(this._dataSource);

  final SpecializationRemoteDataSource _dataSource;

  @override
  Future<List<Specialization>> getAll(SpecializationType type) {
    return _dataSource.getAll(type);
  }

  @override
  Future<List<MeasurementUnit>> getAllMeasurementUnits() {
    return _dataSource.getAllMeasurementUnits();
  }

  @override
  Future<void> create({
    required String name,
    required SpecializationType type,
    required int measurementUnitId,
    int? parentSpecializationId,
  }) {
    return _dataSource.create(
      CreateSpecializationRequestModel(
        name: name,
        type: type,
        measurementUnitId: measurementUnitId,
        parentSpecializationId: parentSpecializationId,
      ),
    );
  }

  @override
  Future<void> update({
    required int id,
    required String name,
    required int measurementUnitId,
  }) {
    return _dataSource.update(
      id,
      UpdateSpecializationRequestModel(
        name: name,
        measurementUnitId: measurementUnitId,
      ),
    );
  }

  @override
  Future<void> toggleDelete(int id) {
    return _dataSource.toggleDelete(id);
  }
}

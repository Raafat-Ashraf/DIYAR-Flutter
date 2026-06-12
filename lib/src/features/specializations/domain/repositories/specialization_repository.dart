import '../entities/specialization.dart';

abstract class SpecializationRepository {
  Future<List<Specialization>> getAll(SpecializationType type);

  Future<List<MeasurementUnit>> getAllMeasurementUnits();

  Future<void> create({
    required String name,
    required SpecializationType type,
    required int measurementUnitId,
    int? parentSpecializationId,
  });

  Future<void> update({
    required int id,
    required String name,
    required int measurementUnitId,
  });

  Future<void> toggleDelete(int id);
}

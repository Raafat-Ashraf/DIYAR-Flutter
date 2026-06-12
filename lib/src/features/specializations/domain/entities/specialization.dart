import 'package:equatable/equatable.dart';

enum SpecializationType {
  product(1, 'Product', 'منتجات'),
  engineeringService(2, 'EngineeringService', 'خدمات هندسية');

  const SpecializationType(this.apiValue, this.apiName, this.arabicLabel);

  final int apiValue;
  final String apiName;
  final String arabicLabel;

  static SpecializationType? fromApi(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      for (final type in SpecializationType.values) {
        if (type.apiValue == value.toInt()) return type;
      }
      return null;
    }

    final normalized = value.toString().trim().toLowerCase();
    for (final type in SpecializationType.values) {
      if (type.apiName.toLowerCase() == normalized) return type;
    }
    return null;
  }
}

class Specialization extends Equatable {
  const Specialization({
    required this.id,
    required this.name,
    required this.type,
    required this.isDeleted,
    required this.children,
    this.measurementUnitId,
    this.measurementUnitName,
  });

  final int id;
  final String name;
  final SpecializationType? type;
  final bool isDeleted;
  final List<Specialization> children;
  final int? measurementUnitId;
  final String? measurementUnitName;

  bool get hasChildren => children.isNotEmpty;

  factory Specialization.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'];

    return Specialization(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: SpecializationType.fromApi(json['type']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      measurementUnitId: json['measurementUnitId'] as int?,
      measurementUnitName: json['measurementUnitName'] as String?,
      children: childrenJson is List
          ? childrenJson
              .whereType<Map<String, dynamic>>()
              .map(Specialization.fromJson)
              .toList()
          : const <Specialization>[],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    isDeleted,
    children,
    measurementUnitId,
    measurementUnitName,
  ];
}

class MeasurementUnit extends Equatable {
  const MeasurementUnit({required this.id, required this.name});

  final int id;
  final String name;

  factory MeasurementUnit.fromJson(Map<String, dynamic> json) {
    return MeasurementUnit(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

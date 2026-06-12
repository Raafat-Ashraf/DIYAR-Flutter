part of 'admin_specializations_cubit.dart';

enum AdminSpecializationsStatus { initial, loading, loaded, failure }

class AdminSpecializationsState extends Equatable {
  const AdminSpecializationsState({
    this.status = AdminSpecializationsStatus.initial,
    this.selectedType = SpecializationType.product,
    this.productRoots = const [],
    this.engineeringRoots = const [],
    this.measurementUnits = const [],
    this.path = const [],
    this.processingIds = const {},
    this.isMutating = false,
    this.errorMessage,
    this.successMessage,
  });

  final AdminSpecializationsStatus status;
  final SpecializationType selectedType;
  final List<Specialization> productRoots;
  final List<Specialization> engineeringRoots;
  final List<MeasurementUnit> measurementUnits;
  final List<int> path;
  final Set<int> processingIds;
  final bool isMutating;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == AdminSpecializationsStatus.loading;
  bool get canGoBack => path.isNotEmpty;

  List<Specialization> get _roots =>
      selectedType == SpecializationType.product
          ? productRoots
          : engineeringRoots;

  List<Specialization> get currentList {
    var list = _roots;
    for (final id in path) {
      final match = _findById(list, id);
      if (match == null) return const [];
      list = match.children;
    }
    return list;
  }

  Specialization? get currentParent {
    if (path.isEmpty) return null;
    var list = _roots;
    Specialization? node;
    for (final id in path) {
      node = _findById(list, id);
      if (node == null) return null;
      list = node.children;
    }
    return node;
  }

  bool get isEmpty =>
      status == AdminSpecializationsStatus.loaded && currentList.isEmpty;

  bool isProcessing(int id) => processingIds.contains(id);

  static Specialization? _findById(List<Specialization> list, int id) {
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  AdminSpecializationsState copyWith({
    AdminSpecializationsStatus? status,
    SpecializationType? selectedType,
    List<Specialization>? productRoots,
    List<Specialization>? engineeringRoots,
    List<MeasurementUnit>? measurementUnits,
    List<int>? path,
    Set<int>? processingIds,
    bool? isMutating,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return AdminSpecializationsState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      productRoots: productRoots ?? this.productRoots,
      engineeringRoots: engineeringRoots ?? this.engineeringRoots,
      measurementUnits: measurementUnits ?? this.measurementUnits,
      path: path ?? this.path,
      processingIds: processingIds ?? this.processingIds,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedType,
    productRoots,
    engineeringRoots,
    measurementUnits,
    path,
    processingIds,
    isMutating,
    errorMessage,
    successMessage,
  ];
}

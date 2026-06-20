import 'package:equatable/equatable.dart';

import '../../../account/domain/entities/account_profile.dart';

enum RequestType {
  material(0, 'Material', 'مادة'),
  service(1, 'Service', 'خدمة هندسية');

  const RequestType(this.apiValue, this.apiName, this.arabicLabel);

  final int apiValue;
  final String apiName;
  final String arabicLabel;

  // Returns the SpecializationType apiValue to use when querying specializations
  int get specializationTypeApiValue => this == RequestType.material ? 1 : 2;

  static RequestType? fromApi(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim().toLowerCase();
    for (final t in values) {
      if (t.apiName.toLowerCase() == str) return t;
      if (t.apiValue.toString() == str) return t;
    }
    return null;
  }
}

enum RequestStatus {
  open(0, 'Open', 'مفتوح'),
  inProgress(1, 'InProgress', 'جارٍ'),
  completed(2, 'Completed', 'مكتمل'),
  cancelled(3, 'Cancelled', 'ملغى');

  const RequestStatus(this.apiValue, this.apiName, this.arabicLabel);

  final int apiValue;
  final String apiName;
  final String arabicLabel;

  static RequestStatus? fromApi(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim().toLowerCase();
    for (final s in values) {
      if (s.apiName.toLowerCase() == str) return s;
      if (s.apiValue.toString() == str) return s;
    }
    return null;
  }
}

enum RequestSortOption {
  newest('CreatedAt', true, 'الأحدث'),
  oldest('CreatedAt', false, 'الأقدم');

  const RequestSortOption(this.sortBy, this.descending, this.label);

  final String sortBy;
  final bool descending;
  final String label;
}

class RequestClient extends Equatable {
  const RequestClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.phoneNumber,
    this.providerType,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? phoneNumber;
  final ProviderType? providerType;

  String get displayName => '$firstName $lastName'.trim();

  factory RequestClient.fromJson(Map<String, dynamic> json) {
    return RequestClient(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      providerType: ProviderType.fromApi(json['providerType']?.toString()),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, phoneNumber, providerType];
}

class RequestCity extends Equatable {
  const RequestCity({required this.id, required this.name});

  final int id;
  final String name;

  factory RequestCity.fromJson(Map<String, dynamic> json) {
    return RequestCity(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class RequestSpecialization extends Equatable {
  const RequestSpecialization({
    required this.id,
    required this.name,
    this.measurementUnitId,
    this.measurementUnitName,
  });

  final int id;
  final String name;
  final int? measurementUnitId;
  final String? measurementUnitName;

  factory RequestSpecialization.fromJson(Map<String, dynamic> json) {
    return RequestSpecialization(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
      measurementUnitId: json['measurementUnitId'] as int?,
      measurementUnitName: json['measurementUnitName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, measurementUnitId, measurementUnitName];
}

class RequestFileItem extends Equatable {
  const RequestFileItem({required this.id, required this.fileUrl, this.description});

  final int id;
  final String fileUrl;
  final String? description;

  bool get isImage {
    final u = fileUrl.toLowerCase();
    return u.endsWith('.jpg') || u.endsWith('.jpeg') ||
        u.endsWith('.png') || u.endsWith('.webp');
  }

  factory RequestFileItem.fromJson(Map<String, dynamic> json) {
    return RequestFileItem(
      id: json['id'] as int? ?? 0,
      fileUrl: (json['fileUrl'] ?? json['url'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, fileUrl, description];
}

class Request extends Equatable {
  const Request({
    required this.id,
    this.requestType,
    this.status,
    this.client,
    this.address,
    this.description,
    this.city,
    this.specialization,
    this.quantity,
    this.expectedBudget,
    this.executionDurationDays,
    this.createdAt,
    this.files = const [],
    this.comments = const [],
  });

  final int id;
  final RequestType? requestType;
  final RequestStatus? status;
  final RequestClient? client;
  final String? address;
  final String? description;
  final RequestCity? city;
  final RequestSpecialization? specialization;
  final double? quantity;
  final double? expectedBudget;
  final int? executionDurationDays;
  final DateTime? createdAt;
  final List<RequestFileItem> files;
  final List<RequestComment> comments;

  factory Request.fromJson(Map<String, dynamic> json) {
    final clientJson = json['client'];
    final cityJson = json['city'];
    final specJson = json['specialization'];
    final filesJson = json['requestFiles'] ?? json['files'];

    return Request(
      id: json['id'] as int? ?? 0,
      requestType: RequestType.fromApi(json['requestType']),
      status: RequestStatus.fromApi(json['status']),
      client: clientJson is Map<String, dynamic>
          ? RequestClient.fromJson(clientJson)
          : null,
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      city: cityJson is Map<String, dynamic>
          ? RequestCity.fromJson(cityJson)
          : null,
      specialization: specJson is Map<String, dynamic>
          ? RequestSpecialization.fromJson(specJson)
          : null,
      quantity: (json['quantity'] as num?)?.toDouble(),
      expectedBudget: (json['expectedBudget'] as num?)?.toDouble(),
      executionDurationDays: json['executionDurationDays'] as int?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      files: filesJson is List
          ? filesJson
              .whereType<Map<String, dynamic>>()
              .map(RequestFileItem.fromJson)
              .toList()
          : const [],
      comments: () {
        final c = json['comments'];
        if (c is! List) return const <RequestComment>[];
        return c
            .whereType<Map<String, dynamic>>()
            .map(RequestComment.fromJson)
            .toList();
      }(),
    );
  }

  @override
  List<Object?> get props => [
    id, requestType, status, client, address, description, city, specialization,
    quantity, expectedBudget, executionDurationDays, createdAt, files, comments,
  ];
}

class PaginatedRequests extends Equatable {
  const PaginatedRequests({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Request> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PaginatedRequests.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return PaginatedRequests(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(Request.fromJson)
          .toList(),
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? itemsJson.length,
      totalCount: json['totalCount'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, pageNumber, pageSize, totalCount, totalPages];
}

class RequestLocalFile extends Equatable {
  const RequestLocalFile({
    required this.path,
    required this.name,
    required this.contentType,
    this.description,
  });

  final String path;
  final String name;
  final String contentType;
  final String? description;

  @override
  List<Object?> get props => [path, name, contentType, description];
}

class CommentUser extends Equatable {
  const CommentUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.providerType,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final ProviderType? providerType;

  String get displayName => '$firstName $lastName'.trim();

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      providerType: ProviderType.fromApi(json['providerType']?.toString()),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, imageUrl, providerType];
}

class RequestComment extends Equatable {
  const RequestComment({
    required this.id,
    required this.content,
    required this.user,
    this.parentCommentId,
    this.createdAt,
  });

  final int id;
  final String content;
  final CommentUser user;
  final int? parentCommentId;
  final DateTime? createdAt;

  bool get isReply => parentCommentId != null;

  factory RequestComment.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return RequestComment(
      id: json['id'] as int? ?? 0,
      content: (json['content'] ?? '').toString(),
      user: userJson is Map<String, dynamic>
          ? CommentUser.fromJson(userJson)
          : const CommentUser(id: '', firstName: '', lastName: ''),
      parentCommentId: json['parentCommentId'] as int?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, content, user, parentCommentId, createdAt];
}

class AddCommentInput {
  const AddCommentInput({
    required this.requestId,
    required this.content,
    this.parentCommentId,
  });

  final int requestId;
  final String content;
  final int? parentCommentId;
}

class RequestStats extends Equatable {
  const RequestStats({
    required this.totalRequests,
    required this.openRequests,
    required this.inProgressRequests,
    required this.completedRequests,
    required this.cancelledRequests,
    required this.materialRequests,
    required this.serviceRequests,
  });

  final int totalRequests;
  final int openRequests;
  final int inProgressRequests;
  final int completedRequests;
  final int cancelledRequests;
  final int materialRequests;
  final int serviceRequests;

  factory RequestStats.fromJson(Map<String, dynamic> json) {
    return RequestStats(
      totalRequests: json['totalRequests'] as int? ?? 0,
      openRequests: json['openRequests'] as int? ?? 0,
      inProgressRequests: json['inProgressRequests'] as int? ?? 0,
      completedRequests: json['completedRequests'] as int? ?? 0,
      cancelledRequests: json['cancelledRequests'] as int? ?? 0,
      materialRequests: json['materialRequests'] as int? ?? 0,
      serviceRequests: json['serviceRequests'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalRequests, openRequests, inProgressRequests,
    completedRequests, cancelledRequests, materialRequests, serviceRequests,
  ];
}

class CreateRequestInput extends Equatable {
  const CreateRequestInput({
    required this.requestType,
    required this.specializationId,
    required this.cityId,
    required this.address,
    this.quantity,
    this.expectedBudget,
    this.executionDurationDays,
    this.description,
    this.files = const [],
  });

  final RequestType requestType;
  final int specializationId;
  final int cityId;
  final String address;
  final double? quantity;
  final double? expectedBudget;
  final int? executionDurationDays;
  final String? description;
  final List<RequestLocalFile> files;

  @override
  List<Object?> get props => [
    requestType, specializationId, cityId, address, quantity, expectedBudget,
    executionDurationDays, description, files,
  ];
}

import 'package:equatable/equatable.dart';

import '../../../account/domain/entities/account_profile.dart';

enum QuotationStatus {
  pending(1, 'Pending', 'قيد الانتظار'),
  accepted(2, 'Accepted', 'مقبول'),
  rejected(3, 'Rejected', 'مرفوض'),
  cancelled(4, 'Cancelled', 'ملغى');

  const QuotationStatus(this.apiValue, this.apiName, this.arabicLabel);

  final int apiValue;
  final String apiName;
  final String arabicLabel;

  static QuotationStatus? fromApi(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim().toLowerCase();
    for (final s in values) {
      if (s.apiName.toLowerCase() == str) return s;
      if (s.apiValue.toString() == str) return s;
    }
    return null;
  }
}

enum QuotationSortOption {
  newest('CreatedAt', true, 'الأحدث'),
  oldest('CreatedAt', false, 'الأقدم'),
  priceHigh('Price', true, 'السعر: الأعلى'),
  priceLow('Price', false, 'السعر: الأقل');

  const QuotationSortOption(this.sortBy, this.descending, this.label);

  final String sortBy;
  final bool descending;
  final String label;
}

class QuotationProvider extends Equatable {
  const QuotationProvider({
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

  factory QuotationProvider.fromJson(Map<String, dynamic> json) {
    return QuotationProvider(
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

class QuotationAttachment extends Equatable {
  const QuotationAttachment({
    required this.id,
    required this.fileUrl,
    this.description,
  });

  final int id;
  final String fileUrl;
  final String? description;

  bool get isImage {
    final u = fileUrl.toLowerCase();
    return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png');
  }

  factory QuotationAttachment.fromJson(Map<String, dynamic> json) {
    return QuotationAttachment(
      id: json['id'] as int? ?? 0,
      fileUrl: (json['fileUrl'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, fileUrl, description];
}

class Quotation extends Equatable {
  const Quotation({
    required this.id,
    required this.requestId,
    required this.provider,
    required this.price,
    this.executionDurationDays,
    this.description,
    this.status,
    this.isContactRevealed = false,
    this.createdAt,
    this.attachments = const [],
  });

  final int id;
  final int requestId;
  final QuotationProvider provider;
  final double price;
  final int? executionDurationDays;
  final String? description;
  final QuotationStatus? status;
  final bool isContactRevealed;
  final DateTime? createdAt;
  final List<QuotationAttachment> attachments;

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final providerJson = json['provider'];
    final attachmentsJson = json['attachments'];
    return Quotation(
      id: json['id'] as int? ?? 0,
      requestId: json['requestId'] as int? ?? 0,
      provider: providerJson is Map<String, dynamic>
          ? QuotationProvider.fromJson(providerJson)
          : const QuotationProvider(id: '', firstName: '', lastName: ''),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      executionDurationDays: json['executionDurationDays'] as int?,
      description: json['description']?.toString(),
      status: QuotationStatus.fromApi(json['status']),
      isContactRevealed: json['isContactRevealed'] as bool? ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      attachments: attachmentsJson is List
          ? attachmentsJson
              .whereType<Map<String, dynamic>>()
              .map(QuotationAttachment.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [id, requestId, provider, price, executionDurationDays, description, status, isContactRevealed, createdAt, attachments];
}

class PaginatedQuotations extends Equatable {
  const PaginatedQuotations({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Quotation> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PaginatedQuotations.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return PaginatedQuotations(
      items: itemsJson.whereType<Map<String, dynamic>>().map(Quotation.fromJson).toList(),
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? itemsJson.length,
      totalCount: json['totalCount'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, pageNumber, pageSize, totalCount, totalPages];
}

class QuotationLocalFile extends Equatable {
  const QuotationLocalFile({
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

class CreateQuotationInput extends Equatable {
  const CreateQuotationInput({
    required this.requestId,
    required this.price,
    this.executionDurationDays,
    this.description,
    this.attachments = const [],
  });

  final int requestId;
  final double price;
  final int? executionDurationDays;
  final String? description;
  final List<QuotationLocalFile> attachments;

  @override
  List<Object?> get props => [requestId, price, executionDurationDays, description, attachments];
}

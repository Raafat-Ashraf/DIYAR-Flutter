import 'package:equatable/equatable.dart';

import '../../../account/domain/entities/account_profile.dart';

enum ShowcaseType {
  portfolio(1, 'Portfolio', 'معرض أعمال'),
  product(2, 'Product', 'منتج');

  const ShowcaseType(this.apiValue, this.apiName, this.arabicLabel);

  final int apiValue;
  final String apiName;
  final String arabicLabel;

  static ShowcaseType? fromApi(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      for (final type in ShowcaseType.values) {
        if (type.apiValue == value.toInt()) return type;
      }
      return null;
    }

    final normalized = value.toString().trim().toLowerCase();
    for (final type in ShowcaseType.values) {
      if (type.apiName.toLowerCase() == normalized) return type;
    }
    return null;
  }

  static ShowcaseType? fromProviderType(ProviderType? providerType) {
    switch (providerType) {
      case ProviderType.freelancer:
        return ShowcaseType.portfolio;
      case ProviderType.supplier:
        return ShowcaseType.product;
      default:
        return null;
    }
  }
}

enum ShowcaseSortOption {
  newest('CreatedAt', true, 'الأحدث'),
  oldest('CreatedAt', false, 'الأقدم'),
  priceAsc('Price', false, 'السعر: من الأقل للأعلى'),
  priceDesc('Price', true, 'السعر: من الأعلى للأقل');

  const ShowcaseSortOption(this.sortBy, this.descending, this.label);

  final String sortBy;
  final bool descending;
  final String label;
}

class ShowcaseFileItem extends Equatable {
  const ShowcaseFileItem({required this.url, this.description});

  final String url;
  final String? description;

  bool get isPdf => url.toLowerCase().endsWith('.pdf');

  factory ShowcaseFileItem.fromJson(Map<String, dynamic> json) {
    return ShowcaseFileItem(
      url:
          (json['url'] ??
                  json['fileUrl'] ??
                  json['filePath'] ??
                  json['path'] ??
                  '')
              .toString(),
      description: (json['description'] ?? json['fileDescription'])
          ?.toString(),
    );
  }

  @override
  List<Object?> get props => [url, description];
}

class ShowcaseOwner extends Equatable {
  const ShowcaseOwner({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.providerType,
    this.phoneNumber,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final ProviderType? providerType;
  final String? phoneNumber;

  String get displayName => '$firstName $lastName'.trim();

  factory ShowcaseOwner.fromJson(Map<String, dynamic> json) {
    return ShowcaseOwner(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['firstname'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['lastname'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'])?.toString(),
      providerType: ProviderType.fromApi(
        (json['providerType'] ?? json['type'])?.toString(),
      ),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? json['mobile'])
          ?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    imageUrl,
    providerType,
    phoneNumber,
  ];
}

class Showcase extends Equatable {
  const Showcase({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.coverImageUrl,
    required this.type,
    required this.createdAt,
    required this.owner,
    required this.files,
    this.isOpen,
  });

  final int id;
  final String title;
  final String description;
  final double? price;
  final String? coverImageUrl;
  final ShowcaseType? type;
  final DateTime? createdAt;
  final ShowcaseOwner? owner;
  final List<ShowcaseFileItem> files;
  final bool? isOpen;

  factory Showcase.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'] ?? json['provider'] ?? json['user'];
    final filesJson =
        json['files'] ?? json['showcaseFiles'] ?? json['attachments'];

    return Showcase(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      coverImageUrl: (json['coverImageUrl'] ?? json['coverImage'])
          ?.toString(),
      type: ShowcaseType.fromApi(json['type'] ?? json['showcaseType']),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['creationDate'] ?? '').toString(),
      ),
      owner: ownerJson is Map<String, dynamic>
          ? ShowcaseOwner.fromJson(ownerJson)
          : null,
      files: filesJson is List
          ? filesJson
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return ShowcaseFileItem.fromJson(item);
                  }
                  if (item is String) return ShowcaseFileItem(url: item);
                  return null;
                })
                .whereType<ShowcaseFileItem>()
                .toList()
          : const <ShowcaseFileItem>[],
      isOpen: json['isOpen'] as bool?,
    );
  }

  Showcase copyWith({bool? isOpen}) => Showcase(
    id: id, title: title, description: description, price: price,
    coverImageUrl: coverImageUrl, type: type, createdAt: createdAt,
    owner: owner, files: files, isOpen: isOpen ?? this.isOpen,
  );

  @override
  List<Object?> get props => [
    id, title, description, price, coverImageUrl, type, createdAt, owner, files, isOpen,
  ];
}

class PaginatedShowcases extends Equatable {
  const PaginatedShowcases({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Showcase> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PaginatedShowcases.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return PaginatedShowcases(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(Showcase.fromJson)
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

class ShowcaseLocalFile extends Equatable {
  const ShowcaseLocalFile({
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

class CreateShowcaseInput extends Equatable {
  const CreateShowcaseInput({
    required this.type,
    required this.title,
    required this.description,
    this.coverImage,
    this.price,
    this.files = const [],
  });

  final ShowcaseType type;
  final String title;
  final String description;
  final double? price;
  final ShowcaseLocalFile? coverImage;
  final List<ShowcaseLocalFile> files;

  @override
  List<Object?> get props => [type, title, description, price, coverImage, files];
}

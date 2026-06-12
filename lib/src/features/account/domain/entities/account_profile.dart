import 'package:equatable/equatable.dart';

enum ProviderType {
  client('Client', 'عميل'),
  supplier('Supplier', 'مورد'),
  freelancer('Freelancer', 'مهندس'),
  admin('Admin', 'مسؤول');

  const ProviderType(this.apiValue, this.arabicName);

  final String apiValue;
  final String arabicName;

  static ProviderType? fromApi(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final type in ProviderType.values) {
      if (type.apiValue.toLowerCase() == normalized) return type;
    }
    return null;
  }
}

enum VerificationStatus {
  notSubmitted('NotSubmitted', 'لم يتم الإرسال'),
  pending('Pending', 'في انتظار الموافقة'),
  approved('Approved', 'تمت الموافقة'),
  rejected('Rejected', 'مرفوض');

  const VerificationStatus(this.apiValue, this.arabicName);

  final String apiValue;
  final String arabicName;

  static VerificationStatus fromApi(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final status in VerificationStatus.values) {
      if (status.apiValue.toLowerCase() == normalized) return status;
    }
    return VerificationStatus.notSubmitted;
  }
}

class Governorate extends Equatable {
  const Governorate({required this.id, required this.name});

  final int id;
  final String name;

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  List<Object?> get props => [id, name];
}

class City extends Equatable {
  const City({required this.id, required this.name});

  final int id;
  final String name;

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class GovernorateCities extends Equatable {
  const GovernorateCities({
    required this.id,
    required this.name,
    required this.cities,
  });

  final int id;
  final String name;
  final List<City> cities;

  factory GovernorateCities.fromJson(Map<String, dynamic> json) {
    final citiesJson = json['cities'] as List<dynamic>? ?? const [];
    return GovernorateCities(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      cities: citiesJson
          .whereType<Map<String, dynamic>>()
          .map(City.fromJson)
          .where((item) => item.id > 0 && item.name.isNotEmpty)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, cities];
}

class AccountProfile extends Equatable {
  const AccountProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    required this.providerType,
    required this.governorate,
    required this.bio,
    required this.companyName,
    required this.yearsOfExperience,
    required this.verificationStatus,
    required this.rejectionReason,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String imageUrl;
  final ProviderType? providerType;
  final Governorate? governorate;
  final String? bio;
  final String? companyName;
  final int? yearsOfExperience;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;

  String get displayName => '$firstName $lastName'.trim();

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    final governorateJson = json['governorate'];
    return AccountProfile(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      providerType: ProviderType.fromApi(json['providerType'] as String?),
      governorate: governorateJson is Map<String, dynamic>
          ? Governorate.fromJson(governorateJson)
          : null,
      bio: json['bio'] as String?,
      companyName: json['companyName'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      verificationStatus: VerificationStatus.fromApi(
        json['verificationStatus'] as String?,
      ),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'imageUrl': imageUrl,
    'providerType': providerType?.apiValue,
    'governorate': governorate?.toJson(),
    'bio': bio,
    'companyName': companyName,
    'yearsOfExperience': yearsOfExperience,
    'verificationStatus': verificationStatus.apiValue,
    'rejectionReason': rejectionReason,
  };

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    imageUrl,
    providerType,
    governorate,
    bio,
    companyName,
    yearsOfExperience,
    verificationStatus,
    rejectionReason,
  ];
}

class VerificationDocument extends Equatable {
  const VerificationDocument({
    required this.documentName,
    required this.filePath,
    required this.fileName,
    required this.contentType,
  });

  final String documentName;
  final String filePath;
  final String fileName;
  final String contentType;

  @override
  List<Object?> get props => [documentName, filePath, fileName, contentType];
}

class VerifyAccountInput extends Equatable {
  const VerifyAccountInput({
    required this.providerType,
    required this.phoneNumber,
    this.governorateId,
    this.bio,
    this.companyName,
    this.yearsOfExperience,
    this.cities = const [],
    this.documents = const [],
  });

  final ProviderType providerType;
  final String phoneNumber;
  final int? governorateId;
  final String? bio;
  final String? companyName;
  final int? yearsOfExperience;
  final List<int> cities;
  final List<VerificationDocument> documents;

  @override
  List<Object?> get props => [
    providerType,
    phoneNumber,
    governorateId,
    bio,
    companyName,
    yearsOfExperience,
    cities,
    documents,
  ];
}

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

class WorkGovernorate extends Equatable {
  const WorkGovernorate({
    this.governorateId = 0,
    required this.governorateName,
    this.cities = const [],
    this.cityIds = const [],
  });
  final int governorateId;
  final String governorateName;
  final List<String> cities;
  final List<int> cityIds;

  factory WorkGovernorate.fromJson(Map<String, dynamic> json) => WorkGovernorate(
        governorateId: json['governorateId'] as int? ?? 0,
        governorateName: json['governorateName'] as String? ?? '',
        cities: (json['cities'] as List?)?.map((e) => e.toString()).toList() ?? [],
        cityIds: (json['cityIds'] as List?)?.cast<int>() ?? const [],
      );

  @override
  List<Object?> get props => [governorateId, governorateName, cities, cityIds];
}

class ProfileSpecializationGroup extends Equatable {
  const ProfileSpecializationGroup({required this.parentName, this.children = const []});
  final String parentName;
  final List<String> children;

  factory ProfileSpecializationGroup.fromJson(Map<String, dynamic> json) =>
      ProfileSpecializationGroup(
        parentName: json['parentName'] as String? ?? '',
        children: (json['children'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  @override
  List<Object?> get props => [parentName, children];
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
    this.phoneNumber,
    this.cityIds = const [],
    this.specializationIds = const [],
    this.worksInAllEgypt = false,
    this.workCities = const [],
    this.profileSpecializations = const [],
    this.latitude,
    this.longitude,
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
  final String? phoneNumber;
  final List<int> cityIds;
  final List<int> specializationIds;
  final bool worksInAllEgypt;
  final List<WorkGovernorate> workCities;
  final List<ProfileSpecializationGroup> profileSpecializations;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

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
      phoneNumber: json['phoneNumber'] as String?,
      cityIds: (json['cityIds'] as List?)?.cast<int>() ?? const [],
      specializationIds: (json['specializationIds'] as List?)?.cast<int>() ?? const [],
      worksInAllEgypt: json['worksInAllEgypt'] as bool? ?? false,
      workCities: (json['workCities'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(WorkGovernorate.fromJson)
              .toList() ??
          const [],
      profileSpecializations: (json['specializations'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ProfileSpecializationGroup.fromJson)
              .toList() ??
          const [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
    'phoneNumber': phoneNumber,
    'cityIds': cityIds,
    'specializationIds': specializationIds,
    'worksInAllEgypt': worksInAllEgypt,
    'workCities': workCities.map((g) => {
      'governorateId': g.governorateId,
      'governorateName': g.governorateName,
      'cities': g.cities,
      'cityIds': g.cityIds,
    }).toList(),
    'specializations': profileSpecializations.map((g) => {
      'parentName': g.parentName,
      'children': g.children,
    }).toList(),
    'latitude': latitude,
    'longitude': longitude,
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
    phoneNumber,
    cityIds,
    specializationIds,
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
    this.worksInAllEgypt = false,
    this.cities = const [],
    this.specializations = const [],
    this.documents = const [],
    this.latitude,
    this.longitude,
  });

  final ProviderType providerType;
  final String phoneNumber;
  final int? governorateId;
  final String? bio;
  final String? companyName;
  final int? yearsOfExperience;
  final bool worksInAllEgypt;
  final List<int> cities;
  final List<int> specializations;
  final List<VerificationDocument> documents;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [
    providerType,
    phoneNumber,
    governorateId,
    bio,
    companyName,
    yearsOfExperience,
    cities,
    specializations,
    documents,
  ];
}

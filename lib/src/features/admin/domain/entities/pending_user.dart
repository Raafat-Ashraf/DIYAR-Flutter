import 'package:equatable/equatable.dart';

import '../../../account/domain/entities/account_profile.dart';

class PendingUserDocument extends Equatable {
  const PendingUserDocument({required this.documentName, required this.fileUrl});

  final String documentName;
  final String fileUrl;

  factory PendingUserDocument.fromJson(Map<String, dynamic> json) {
    return PendingUserDocument(
      documentName: (json['documentName'] ?? json['name'] ?? '').toString(),
      fileUrl: (json['documentUrl'] ??
              json['fileUrl'] ??
              json['filePath'] ??
              json['url'] ??
              '')
          .toString(),
    );
  }

  @override
  List<Object?> get props => [documentName, fileUrl];
}

class PendingUser extends Equatable {
  const PendingUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.providerType,
    required this.governorate,
    required this.bio,
    required this.companyName,
    required this.yearsOfExperience,
    required this.verificationStatus,
    required this.submittedAt,
    required this.documents,
    this.specializations = const [],
    this.workCities = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String imageUrl;
  final ProviderType? providerType;
  final Governorate? governorate;
  final String? bio;
  final String? companyName;
  final int? yearsOfExperience;
  final VerificationStatus verificationStatus;
  final DateTime? submittedAt;
  final List<PendingUserDocument> documents;
  final List<String> specializations;
  final List<String> workCities;

  String get displayName => '$firstName $lastName'.trim();

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    final governorateJson = json['governorate'];
    final documentsJson = json['officialDocuments'] ?? json['documents'];

    return PendingUser(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
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
      submittedAt: DateTime.tryParse(
        (json['verificationSubmittedAt'] ??
                json['submittedAt'] ??
                json['createdAt'] ??
                '')
            .toString(),
      ),
      documents: documentsJson is List
          ? documentsJson
              .whereType<Map<String, dynamic>>()
              .map(PendingUserDocument.fromJson)
              .toList()
          : const [],
      specializations: (json['specializations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      workCities: (json['workCities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    id, firstName, lastName, email, imageUrl, providerType, governorate,
    bio, companyName, yearsOfExperience, verificationStatus, submittedAt,
    documents, specializations, workCities,
  ];
}

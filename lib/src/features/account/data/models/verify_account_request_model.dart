import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/account_profile.dart';

class VerifyAccountRequestModel {
  const VerifyAccountRequestModel(this.input);

  final VerifyAccountInput input;

  Future<FormData> toFormData() async {
    final data = <String, dynamic>{
      'ProviderType': input.providerType.apiValue,
      'PhoneNumber': input.phoneNumber,
    };

    if (input.governorateId != null) {
      data['GovernorateId'] = input.governorateId;
    }

    data['WorksInAllEgypt'] = input.worksInAllEgypt;

    if (!input.worksInAllEgypt && input.cities.isNotEmpty) {
      data['Cities'] = input.cities;
    }

    if (input.specializations.isNotEmpty) {
      data['Specializations'] = input.specializations;
    }

    final bio = input.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      data['Bio'] = bio;
    }

    final companyName = input.companyName?.trim();
    if (companyName != null && companyName.isNotEmpty) {
      data['CompanyName'] = companyName;
    }

    if (input.yearsOfExperience != null) {
      data['YearsOfExperience'] = input.yearsOfExperience;
    }

    if (input.latitude != null) data['Latitude'] = input.latitude;
    if (input.longitude != null) data['Longitude'] = input.longitude;

    for (var i = 0; i < input.documents.length; i++) {
      final document = input.documents[i];
      data['OfficialDocumentRequests[$i].DocumentName'] = document.documentName;
      data['OfficialDocumentRequests[$i].Document'] =
          await MultipartFile.fromFile(
            document.filePath,
            filename: document.fileName,
            contentType: MediaType.parse(document.contentType),
          );
    }

    return FormData.fromMap(data);
  }
}

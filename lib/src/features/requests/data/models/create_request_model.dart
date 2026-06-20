import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/request.dart';

class CreateRequestModel {
  const CreateRequestModel(this.input);

  final CreateRequestInput input;

  Future<FormData> toFormData() async {
    final data = <String, dynamic>{
      'RequestType': input.requestType.apiValue,
      'SpecializationId': input.specializationId,
      'CityId': input.cityId,
      'Address': input.address,
    };

    if (input.quantity != null) data['Quantity'] = input.quantity;
    if (input.expectedBudget != null) data['ExpectedBudget'] = input.expectedBudget;
    if (input.executionDurationDays != null) {
      data['ExecutionDurationDays'] = input.executionDurationDays;
    }
    final desc = input.description?.trim();
    if (desc != null && desc.isNotEmpty) data['Description'] = desc;

    for (var i = 0; i < input.files.length; i++) {
      final file = input.files[i];
      data['RequestFiles[$i].File'] = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: _safeMediaType(file.contentType),
      );
      final fileDesc = file.description?.trim();
      if (fileDesc != null && fileDesc.isNotEmpty) {
        data['RequestFiles[$i].Description'] = fileDesc;
      }
    }

    return FormData.fromMap(data);
  }

  static MediaType _safeMediaType(String contentType) {
    try {
      return MediaType.parse(contentType);
    } catch (_) {
      return MediaType.parse('application/octet-stream');
    }
  }
}

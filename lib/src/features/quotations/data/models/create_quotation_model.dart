import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/quotation.dart';

class CreateQuotationModel {
  const CreateQuotationModel(this.input);

  final CreateQuotationInput input;

  Future<FormData> toFormData() async {
    final data = <String, dynamic>{
      'RequestId': input.requestId,
      'Price': input.price,
    };

    if (input.executionDurationDays != null) {
      data['ExecutionDurationDays'] = input.executionDurationDays;
    }
    final desc = input.description?.trim();
    if (desc != null && desc.isNotEmpty) data['Description'] = desc;

    for (var i = 0; i < input.attachments.length; i++) {
      final file = input.attachments[i];
      data['Attachments[$i].File'] = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: _safeMediaType(file.contentType),
      );
      final fileDesc = file.description?.trim();
      if (fileDesc != null && fileDesc.isNotEmpty) {
        data['Attachments[$i].Description'] = fileDesc;
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

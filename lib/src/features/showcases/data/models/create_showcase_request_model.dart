import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/showcase.dart';

class CreateShowcaseRequestModel {
  const CreateShowcaseRequestModel(this.input);

  final CreateShowcaseInput input;

  Future<FormData> toFormData() async {
    final data = <String, dynamic>{
      'Title': input.title,
      'Description': input.description,
    };

    if (input.price != null) {
      data['Price'] = input.price;
    }

    final coverImage = input.coverImage;
    if (coverImage != null) {
      data['CoverImageUrl'] = await MultipartFile.fromFile(
        coverImage.path,
        filename: coverImage.name,
        contentType: MediaType.parse(coverImage.contentType),
      );
    }

    for (var i = 0; i < input.files.length; i++) {
      final file = input.files[i];
      data['ShowcaseFiles[$i].FileUrl'] = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: MediaType.parse(file.contentType),
      );
      final description = file.description?.trim();
      if (description != null && description.isNotEmpty) {
        data['ShowcaseFiles[$i].Description'] = description;
      }
    }

    return FormData.fromMap(data);
  }
}

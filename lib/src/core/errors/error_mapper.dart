import 'package:dio/dio.dart';

import '../localization/backend_message_translator.dart';
import 'app_failure.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppFailure fromDio(DioException error) {
    final response = error.response;
    final parsed = fromResponseBody(response?.data, response?.statusCode);
    if (parsed != null) return parsed;

    return AppFailure(
      message: _fallbackFor(error, response),
      statusCode: response?.statusCode,
    );
  }

  static AppFailure? fromResponseBody(Object? data, int? statusCode) {
    if (data is String && data.trim().isNotEmpty) {
      return AppFailure(
        message: BackendMessageTranslator.translate(data),
        statusCode: statusCode,
      );
    }

    if (data is! Map) return null;

    final topLevelErrors = _collectErrors(data['errors']);
    final extensionErrors = data['extensions'] is Map
        ? _collectErrors((data['extensions'] as Map)['errors'])
        : const <_BackendError>[];
    final allErrors = [...topLevelErrors, ...extensionErrors];

    if (allErrors.isNotEmpty) {
      return AppFailure(
        message: _formatMessages(allErrors),
        code: allErrors.first.code,
        statusCode: allErrors.first.statusCode ?? statusCode,
      );
    }

    final detail = data['detail'] ?? data['title'] ?? data['message'];
    if (detail is String && detail.trim().isNotEmpty) {
      return AppFailure(
        message: BackendMessageTranslator.translate(detail),
        statusCode: statusCode,
      );
    }

    return null;
  }

  static String _formatMessages(List<_BackendError> errors) {
    final translated = errors
        .map(
          (error) => BackendMessageTranslator.translate(
            error.description,
            code: error.code,
            field: error.field,
          ),
        )
        .where((message) => message.trim().isNotEmpty)
        .toSet()
        .toList();

    if (translated.length == 1) return translated.single;
    return translated.map((message) => '• $message').join('\n');
  }

  static List<_BackendError> _collectErrors(Object? errors, {String? field}) {
    if (errors == null) return const [];

    if (errors is String) {
      return [_BackendError(description: errors, field: field)];
    }

    if (errors is List) {
      return errors
          .expand((error) => _collectErrors(error, field: field))
          .toList();
    }

    if (errors is Map) {
      final description = errors['description'] ?? errors['Description'];
      if (description is String && description.trim().isNotEmpty) {
        final code = errors['code'] ?? errors['Code'];
        final statusCode = errors['statusCode'] ?? errors['StatusCode'];
        return [
          _BackendError(
            description: description,
            code: code is String ? code : null,
            statusCode: statusCode is int ? statusCode : null,
            field: field,
          ),
        ];
      }

      return errors.entries
          .expand(
            (entry) => _collectErrors(
              entry.value,
              field: entry.key?.toString(),
            ),
          )
          .toList();
    }

    return const [];
  }

  static String _fallbackFor(DioException error, Response? response) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
      case DioExceptionType.connectionError:
        return 'لا يمكن الوصول إلى الخادم. تحقق من اتصال الإنترنت.';
      case DioExceptionType.badCertificate:
        return 'شهادة الخادم غير موثوقة.';
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final detail = _rawErrorDetail(response);
        final status = response?.statusCode;
        if (detail != null) {
          return status != null
              ? 'حدث خطأ ($status): $detail'
              : 'حدث خطأ: $detail';
        }
        return status != null
            ? 'حدث خطأ غير متوقع ($status). حاول مرة أخرى.'
            : 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }

  static String? _rawErrorDetail(Response? response) {
    final data = response?.data;

    String? raw;
    if (data is String && data.trim().isNotEmpty) {
      raw = data.trim();
    } else if (data is Map && data.isNotEmpty) {
      raw = data.toString();
    } else if (data is List && data.isNotEmpty) {
      raw = data.toString();
    } else if (response?.statusMessage?.trim().isNotEmpty ?? false) {
      raw = response!.statusMessage!.trim();
    }

    if (raw == null) return null;
    return raw.length > 300 ? '${raw.substring(0, 300)}…' : raw;
  }
}

class _BackendError {
  const _BackendError({
    required this.description,
    this.code,
    this.statusCode,
    this.field,
  });

  final String description;
  final String? code;
  final int? statusCode;
  final String? field;
}

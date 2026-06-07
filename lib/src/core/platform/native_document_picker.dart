import 'package:flutter/services.dart';

class PickedNativeDocument {
  const PickedNativeDocument({
    required this.path,
    required this.name,
    required this.contentType,
    required this.size,
  });

  final String path;
  final String name;
  final String contentType;
  final int size;

  factory PickedNativeDocument.fromMap(Map<dynamic, dynamic> map) {
    return PickedNativeDocument(
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? 'document',
      contentType: map['contentType'] as String? ?? 'application/octet-stream',
      size: map['size'] as int? ?? 0,
    );
  }
}

class NativeDocumentPicker {
  const NativeDocumentPicker();

  static const _channel = MethodChannel('diyar/document_picker');

  Future<PickedNativeDocument?> pickDocument() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDocument',
    );
    if (result == null) return null;
    final document = PickedNativeDocument.fromMap(result);
    if (document.path.isEmpty) return null;
    return document;
  }
}

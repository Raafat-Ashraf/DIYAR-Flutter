import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.referenceId,
  });

  final int id;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final int? referenceId;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        content: content,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        type: type,
        referenceId: referenceId,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseUtc(json['createdAt']),
      type: json['type']?.toString(),
      referenceId: json['referenceId'] as int?,
    );
  }

  static DateTime _parseUtc(dynamic value) {
    final str = (value ?? '').toString().trim();
    if (str.isEmpty) return DateTime.now();
    // Backend sends UTC without 'Z' — append it so Dart treats it as UTC
    final withZ = str.endsWith('Z') || str.contains('+') ? str : '${str}Z';
    return DateTime.tryParse(withZ)?.toLocal() ?? DateTime.now();
  }

  @override
  List<Object?> get props => [id, title, content, isRead, createdAt, type, referenceId];
}

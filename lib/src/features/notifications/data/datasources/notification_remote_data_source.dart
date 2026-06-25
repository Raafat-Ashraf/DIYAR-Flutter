import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_item.dart';

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.totalPages,
    required this.totalCount,
    required this.pageNumber,
  });
  final List<NotificationItem> items;
  final int totalPages;
  final int totalCount;
  final int pageNumber;
}

abstract class NotificationRemoteDataSource {
  Future<int> getUnreadCount();
  Future<NotificationPage> getAll({required int page, bool onlyUnread = false});
  Future<void> markAsRead(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get<int>(ApiConstants.unreadNotificationsCount);
    return response;
  }

  @override
  Future<NotificationPage> getAll({required int page, bool onlyUnread = false}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.getAllNotifications,
      queryParameters: {
        'pageNumber': page,
        'pageSize': 20,
        if (onlyUnread) 'onlyUnread': true,
      },
    );
    final items = (response['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
    return NotificationPage(
      items: items,
      totalPages: response['totalPages'] as int? ?? 1,
      totalCount: response['totalCount'] as int? ?? items.length,
      pageNumber: response['pageNumber'] as int? ?? page,
    );
  }

  @override
  Future<void> markAsRead(int id) async {
    await _client.put<dynamic>('${ApiConstants.markNotificationRead}/$id');
  }
}

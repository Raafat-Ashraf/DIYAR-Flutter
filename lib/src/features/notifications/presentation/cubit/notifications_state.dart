part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.unreadItems = const [],
    this.unreadCount = 0,
    this.allPage = 1,
    this.allTotalPages = 1,
    this.unreadPage = 1,
    this.unreadTotalPages = 1,
    this.isLoadingMore = false,
  });

  final List<NotificationItem> items;
  final List<NotificationItem> unreadItems;
  final int unreadCount;
  final int allPage;
  final int allTotalPages;
  final int unreadPage;
  final int unreadTotalPages;
  final bool isLoadingMore;

  bool get allHasMore => allPage < allTotalPages;
  bool get unreadHasMore => unreadPage < unreadTotalPages;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    List<NotificationItem>? unreadItems,
    int? unreadCount,
    int? allPage,
    int? allTotalPages,
    int? unreadPage,
    int? unreadTotalPages,
    bool? isLoadingMore,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadItems: unreadItems ?? this.unreadItems,
        unreadCount: unreadCount ?? this.unreadCount,
        allPage: allPage ?? this.allPage,
        allTotalPages: allTotalPages ?? this.allTotalPages,
        unreadPage: unreadPage ?? this.unreadPage,
        unreadTotalPages: unreadTotalPages ?? this.unreadTotalPages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [
        items,
        unreadItems,
        unreadCount,
        allPage,
        allTotalPages,
        unreadPage,
        unreadTotalPages,
        isLoadingMore,
      ];
}

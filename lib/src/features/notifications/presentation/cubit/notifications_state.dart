part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.allPage = 1,
    this.allTotalPages = 1,
    this.isLoadingMore = false,
  });

  final List<NotificationItem> items;
  final int unreadCount;
  final int allPage;
  final int allTotalPages;
  final bool isLoadingMore;

  bool get allHasMore => allPage < allTotalPages;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    int? allPage,
    int? allTotalPages,
    bool? isLoadingMore,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        allPage: allPage ?? this.allPage,
        allTotalPages: allTotalPages ?? this.allTotalPages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [items, unreadCount, allPage, allTotalPages, isLoadingMore];
}

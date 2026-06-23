import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../cubit/notifications_cubit.dart';
import '../../domain/entities/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<NotificationsCubit>(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _allScrollController = ScrollController();
  final _unreadScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<NotificationsCubit>().load();

    _allScrollController.addListener(() {
      if (_allScrollController.position.pixels >=
          _allScrollController.position.maxScrollExtent - 100) {
        context.read<NotificationsCubit>().loadMoreAll();
      }
    });
    _unreadScrollController.addListener(() {
      if (_unreadScrollController.position.pixels >=
          _unreadScrollController.position.maxScrollExtent - 100) {
        context.read<NotificationsCubit>().loadMoreUnread();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allScrollController.dispose();
    _unreadScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                if (state.unreadCount == 0) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () async {
                    for (final n in state.items.where((n) => !n.isRead)) {
                      await context.read<NotificationsCubit>().markAsRead(n.id);
                    }
                  },
                  child: const Text('قراءة الكل'),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('لم تقرأها'),
                      if (state.unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.unreadCount}',
                            style: TextStyle(color: scheme.onPrimary, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Tab(text: 'الجميع'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _NotificationsList(
              scrollController: _unreadScrollController,
              selector: (state) => state.unreadItems,
              hasMore: (state) => state.unreadHasMore,
              isLoadingMore: (state) => state.isLoadingMore,
              emptyText: 'لا توجد إشعارات غير مقروءة',
            ),
            _NotificationsList(
              scrollController: _allScrollController,
              selector: (state) => state.items,
              hasMore: (state) => state.allHasMore,
              isLoadingMore: (state) => state.isLoadingMore,
              emptyText: 'لا توجد إشعارات',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.scrollController,
    required this.selector,
    required this.hasMore,
    required this.isLoadingMore,
    required this.emptyText,
  });

  final ScrollController scrollController;
  final List<NotificationItem> Function(NotificationsState) selector;
  final bool Function(NotificationsState) hasMore;
  final bool Function(NotificationsState) isLoadingMore;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final items = selector(state);
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 64, color: scheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(emptyText, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          itemCount: items.length + (hasMore(state) ? 1 : 0),
          separatorBuilder: (_, _) => Divider(height: 1, color: scheme.outlineVariant),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final n = items[index];
            return _NotificationTile(
              notification: n,
              onTap: () => context.push(AppRoutes.notificationDetail, extra: n),
            );
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? scheme.primary.withValues(alpha: .05) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: .12),
                  child: Icon(Icons.notifications_rounded,
                      color: scheme.primary, size: 20),
                ),
                if (isUnread)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.content,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relTime(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}

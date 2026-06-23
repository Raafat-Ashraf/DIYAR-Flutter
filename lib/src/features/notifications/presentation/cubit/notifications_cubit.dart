import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/signalr_service.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/notification_item.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationRemoteDataSource dataSource,
    required SignalRService signalRService,
  })  : _dataSource = dataSource,
        _signalR = signalRService,
        super(const NotificationsState()) {
    _signalR.addListener(_onSignalRNotification);
  }

  final NotificationRemoteDataSource _dataSource;
  final SignalRService _signalR;

  Future<void> load() async {
    try {
      final allPage = await _dataSource.getAll(page: 1);
      final unreadPage = await _dataSource.getAll(page: 1, onlyUnread: true);
      emit(state.copyWith(
        items: allPage.items,
        allPage: 1,
        allTotalPages: allPage.totalPages,
        unreadItems: unreadPage.items,
        unreadPage: 1,
        unreadTotalPages: unreadPage.totalPages,
        unreadCount: unreadPage.items.where((n) => !n.isRead).length,
      ));
    } catch (_) {}
  }

  Future<void> loadMoreAll() async {
    if (!state.allHasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await _dataSource.getAll(page: state.allPage + 1);
      emit(state.copyWith(
        items: [...state.items, ...next.items],
        allPage: next.pageNumber,
        allTotalPages: next.totalPages,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMoreUnread() async {
    if (!state.unreadHasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await _dataSource.getAll(page: state.unreadPage + 1, onlyUnread: true);
      emit(state.copyWith(
        unreadItems: [...state.unreadItems, ...next.items],
        unreadPage: next.pageNumber,
        unreadTotalPages: next.totalPages,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onSignalRNotification(NotificationPayload payload) {
    final newItem = NotificationItem(
      id: payload.id,
      title: payload.title,
      content: payload.content,
      isRead: false,
      createdAt: DateTime.now(),
      type: payload.type,
      referenceId: payload.referenceId,
    );
    emit(state.copyWith(
      items: [newItem, ...state.items],
      unreadItems: [newItem, ...state.unreadItems],
      unreadCount: state.unreadCount + 1,
    ));
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dataSource.markAsRead(id);
      final updatedAll = state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      final updatedUnread = state.unreadItems.where((n) => n.id != id).toList();
      final unread = updatedAll.where((n) => !n.isRead).length;
      emit(state.copyWith(items: updatedAll, unreadItems: updatedUnread, unreadCount: unread));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _signalR.removeListener(_onSignalRNotification);
    return super.close();
  }
}

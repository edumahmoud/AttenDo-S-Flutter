import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Notifications State ───

class NotificationsState {
  final List<DBNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  NotificationsState copyWith({
    List<DBNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifications Controller ───

class NotificationsController extends StateNotifier<NotificationsState> {
  final StudentApiService _apiService;
  final SupabaseService _supabaseService;

  NotificationsController(this._apiService, this._supabaseService)
      : super(const NotificationsState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _apiService.fetchNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final previousNotifications = state.notifications;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) =>
              n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    try {
      await _apiService.markNotificationRead(notificationId);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(
        notifications: previousNotifications,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final previousNotifications = state.notifications;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    );
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      state = state.copyWith(
        notifications: previousNotifications,
        error: _friendlyError(e),
      );
    }
  }

  int getUnreadCount() => state.unreadCount;

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load notifications. Please try again.';
  }
}

// ─── Provider ───

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(
    ref.watch(studentApiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

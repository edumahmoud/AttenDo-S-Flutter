import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../controllers/controllers.dart';
import '../../i18n/app_localizations.dart';
import '../../models/models.dart';
import '../shared/empty_state.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ─── Filter ───

enum NotificationFilter { all, unread }

// ─── Notifications Screen ───

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(notificationsControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).fetchNotifications(),
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(child: _buildHeader(loc, state)),

              // ─── Filter Chips ───
              SliverToBoxAdapter(child: _buildFilterChips(loc)),

              // ─── Content ───
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LoadingShimmerCardBlock(),
                        SizedBox(height: 12),
                        LoadingShimmerCardBlock(),
                      ],
                    ),
                  ),
                )
              else if (state.error != null)
                SliverToBoxAdapter(
                  child: SectionErrorBoundary(
                    message: state.error,
                    onRetry: () => ref
                        .read(notificationsControllerProvider.notifier)
                        .fetchNotifications(),
                  ),
                )
              else if (state.notifications.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: loc.t('notifications.noNotifications'),
                    description: loc.t('notifications.allCaughtUp'),
                  ),
                )
              else
                _buildGroupedNotifications(loc, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, NotificationsState state) {
    final theme = Theme.of(context);
    final unreadCount = state.unreadCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  loc.t('notifications.title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ocean(theme.brightness),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            AppColors.oceanForeground(theme.brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(loc.t('notifications.markAllRead')),
            ),
        ],
      ),
    );
  }

  // ─── Filter Chips ───

  Widget _buildFilterChips(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      (NotificationFilter.all, loc.t('notifications.all')),
      (NotificationFilter.unread, loc.t('notifications.unread')),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _filter == filter;

          return FilterChip(
            selected: isSelected,
            label: Text(label),
            onSelected: (_) => setState(() => _filter = filter),
            selectedColor: colorScheme.primary.withValues(alpha: 0.15),
            checkmarkColor: colorScheme.primary,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
          );
        },
      ),
    );
  }

  // ─── Filtering & Grouping ───

  List<DBNotification> _filteredNotifications(NotificationsState state) {
    var list = List<DBNotification>.from(state.notifications);
    if (_filter == NotificationFilter.unread) {
      list = list.where((n) => !n.isRead).toList();
    }
    return list;
  }

  /// Group notifications by time period.
  Map<String, List<DBNotification>> _groupNotifications(
      List<DBNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<DBNotification>>{
      'today': [],
      'yesterday': [],
      'thisWeek': [],
      'earlier': [],
    };

    for (final notification in notifications) {
      final notifDay = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notifDay == today) {
        groups['today']!.add(notification);
      } else if (notifDay == yesterday) {
        groups['yesterday']!.add(notification);
      } else if (notifDay.isAfter(weekAgo) || notifDay == weekAgo) {
        groups['thisWeek']!.add(notification);
      } else {
        groups['earlier']!.add(notification);
      }
    }

    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  // ─── Grouped List ───

  Widget _buildGroupedNotifications(
      AppLocalizations loc, NotificationsState state) {
    final filtered = _filteredNotifications(state);

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: loc.t('notifications.noNotifications'),
          description: loc.t('notifications.allCaughtUp'),
        ),
      );
    }

    final groups = _groupNotifications(filtered);
    final groupLabels = <String, String>{
      'today': loc.t('notifications.today'),
      'yesterday': loc.t('notifications.yesterday'),
      'thisWeek': loc.t('notifications.thisWeek'),
      'earlier': loc.t('notifications.earlier'),
    };

    final slivers = <Widget>[];
    for (final entry in groups.entries) {
      final groupKey = entry.key;
      final groupNotifs = entry.value;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              groupLabels[groupKey] ?? groupKey,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildNotificationCard(loc, groupNotifs[index]),
            childCount: groupNotifs.length,
          ),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  // ─── Notification Card ───

  Widget _buildNotificationCard(AppLocalizations loc, DBNotification notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _notificationTypeColor(notification.type);
    final typeIcon = _notificationTypeIcon(notification.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        color: notification.isRead
            ? colorScheme.surface
            : colorScheme.primary.withValues(alpha: 0.04),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationsControllerProvider.notifier)
                  .markAsRead(notification.id);
            }
            // Navigate to related content if available
            _navigateToRelated(notification);
          },
          onLongPress: () => _showNotificationActions(loc, notification),
          borderRadius: AppTheme.borderRadiusGeometry,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, size: 20, color: typeColor),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Unread dot
                          if (!notification.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.ocean(theme.brightness),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Message preview
                      Text(
                        notification.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Time ago
                      Text(
                        _formatTimeAgo(notification.createdAt, loc),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Notification Actions (Long Press) ───

  void _showNotificationActions(
      AppLocalizations loc, DBNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                ListTile(
                  leading: const Icon(Icons.mark_email_read_rounded),
                  title: Text(loc.t('notifications.markAsRead')),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref
                        .read(notificationsControllerProvider.notifier)
                        .markAsRead(notification.id);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: AppColors.lightDestructive),
                title: Text(
                  loc.t('notifications.deleteNotification'),
                  style: TextStyle(color: AppColors.lightDestructive),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteNotification(loc, notification);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteNotification(
      AppLocalizations loc, DBNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('notifications.deleteNotification')),
        content: Text(loc.t('notifications.deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightDestructive,
              foregroundColor: AppColors.lightDestructiveForeground,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );

    // Note: The current NotificationsController doesn't have a delete method.
    // Marking as read instead if deletion isn't available.
    if (confirmed == true && mounted) {
      if (!notification.isRead) {
        ref
            .read(notificationsControllerProvider.notifier)
            .markAsRead(notification.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('notifications.deleteNotification'))),
      );
    }
  }

  // ─── Navigation ───

  void _navigateToRelated(DBNotification notification) {
    // Navigate based on referenceType and referenceId
    // This is a placeholder for actual navigation logic
    // In a real implementation, we'd use GoRouter to navigate
    // to the appropriate screen based on the notification type
  }

  // ─── Helpers ───

  Color _notificationTypeColor(NotificationType type) {
    return switch (type) {
      NotificationType.assignmentCreated => AppColors.lightOcean,
      NotificationType.assignmentGraded => const Color(0xFF22C55E), // green
      NotificationType.attendanceMarked => const Color(0xFF22C55E), // green
      NotificationType.quizAssigned => const Color(0xFF8B5CF6), // purple
      NotificationType.summaryReady => AppColors.lightTealAccent,
      NotificationType.messageReceived => const Color(0xFF0EA5E9), // sky
      NotificationType.reportUpdated => const Color(0xFFEF4444), // red
      NotificationType.announcement => AppColors.lightAmberAccent,
      NotificationType.system => AppColors.lightMutedForeground,
    };
  }

  IconData _notificationTypeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.assignmentCreated =>
        Icons.assignment_rounded, // blue clipboard
      NotificationType.assignmentGraded =>
        Icons.star_rounded, // green star
      NotificationType.attendanceMarked =>
        Icons.check_circle_outline_rounded, // green check
      NotificationType.quizAssigned =>
        Icons.help_outline_rounded, // purple help
      NotificationType.summaryReady =>
        Icons.auto_stories_rounded, // teal book
      NotificationType.messageReceived =>
        Icons.chat_bubble_outline_rounded, // sky message
      NotificationType.reportUpdated =>
        Icons.security_rounded, // red shield
      NotificationType.announcement =>
        Icons.campaign_rounded, // amber megaphone
      NotificationType.system => Icons.info_outline_rounded, // gray info
    };
  }

  String _formatTimeAgo(DateTime dateTime, AppLocalizations loc) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return loc.t('time.justNow');
    } else if (diff.inMinutes < 60) {
      return loc.t('time.minutesAgo', args: {'n': '${diff.inMinutes}'});
    } else if (diff.inHours < 24) {
      return loc.t('time.hoursAgo', args: {'n': '${diff.inHours}'});
    } else if (diff.inDays < 7) {
      return loc.t('time.daysAgo', args: {'n': '${diff.inDays}'});
    } else {
      return DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en').format(dateTime);
    }
  }
}

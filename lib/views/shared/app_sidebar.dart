import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../config/constants/app_constants.dart';
import '../../config/routes/route_guards.dart';
import '../../i18n/app_localizations.dart';

/// Navigation item model for sidebar and bottom nav.
class NavItem {
  final String key;
  final IconData icon;
  final IconData? activeIcon;
  final String Function(AppLocalizations) labelBuilder;
  final String route;

  const NavItem({
    required this.key,
    required this.icon,
    this.activeIcon,
    required this.labelBuilder,
    required this.route,
  });
}

/// All navigation items for the student sidebar.
const List<NavItem> studentNavItems = [
  NavItem(
    key: 'dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    labelBuilder: _lDashboard,
    route: '/student/dashboard',
  ),
  NavItem(
    key: 'subjects',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    labelBuilder: _lSubjects,
    route: '/student/subjects',
  ),
  NavItem(
    key: 'summaries',
    icon: Icons.summarize_outlined,
    activeIcon: Icons.summarize_rounded,
    labelBuilder: _lSummaries,
    route: '/student/summaries',
  ),
  NavItem(
    key: 'chat',
    icon: Icons.chat_outlined,
    activeIcon: Icons.chat_rounded,
    labelBuilder: _lChat,
    route: '/student/chat',
  ),
  NavItem(
    key: 'assignments',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    labelBuilder: _lAssignments,
    route: '/student/assignments',
  ),
  NavItem(
    key: 'files',
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder_rounded,
    labelBuilder: _lFiles,
    route: '/student/files',
  ),
  NavItem(
    key: 'videos',
    icon: Icons.play_circle_outline,
    activeIcon: Icons.play_circle_rounded,
    labelBuilder: _lVideos,
    route: '/student/videos',
  ),
  NavItem(
    key: 'tracking',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    labelBuilder: _lTracking,
    route: '/student/tracking',
  ),
  NavItem(
    key: 'teachers',
    icon: Icons.school_outlined,
    activeIcon: Icons.school_rounded,
    labelBuilder: _lTeachers,
    route: '/student/teachers',
  ),
  NavItem(
    key: 'calendar',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today_rounded,
    labelBuilder: _lCalendar,
    route: '/student/calendar',
  ),
  NavItem(
    key: 'todos',
    icon: Icons.check_circle_outline,
    activeIcon: Icons.check_circle_rounded,
    labelBuilder: _lTodos,
    route: '/student/todos',
  ),
  NavItem(
    key: 'notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications_rounded,
    labelBuilder: _lNotifications,
    route: '/student/notifications',
  ),
  NavItem(
    key: 'reports',
    icon: Icons.report_outlined,
    activeIcon: Icons.report_rounded,
    labelBuilder: _lReports,
    route: '/student/reports',
  ),
  NavItem(
    key: 'quiz',
    icon: Icons.quiz_outlined,
    activeIcon: Icons.quiz_rounded,
    labelBuilder: _lQuiz,
    route: '/student/quiz',
  ),
  NavItem(
    key: 'settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    labelBuilder: _lSettings,
    route: '/student/settings',
  ),
];

// Label builders
String _lDashboard(AppLocalizations l) => l.navDashboard;
String _lSubjects(AppLocalizations l) => l.navSubjects;
String _lSummaries(AppLocalizations l) => l.navSummaries;
String _lChat(AppLocalizations l) => l.navChat;
String _lAssignments(AppLocalizations l) => l.navAssignments;
String _lFiles(AppLocalizations l) => l.navFiles;
String _lVideos(AppLocalizations l) => l.navVideos;
String _lTracking(AppLocalizations l) => l.navTracking;
String _lTeachers(AppLocalizations l) => l.navTeachers;
String _lCalendar(AppLocalizations l) => l.navCalendar;
String _lTodos(AppLocalizations l) => l.navTodos;
String _lNotifications(AppLocalizations l) => l.navNotifications;
String _lReports(AppLocalizations l) => l.navReports;
String _lQuiz(AppLocalizations l) => l.t('nav.questionBank');
String _lSettings(AppLocalizations l) => l.navSettings;

/// Sidebar component with navigation items, active styling,
/// icons + labels, collapse/expand toggle, and user info at bottom.
class AppSidebar extends ConsumerStatefulWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final loc = AppLocalizations.of(context);
    final isCollapsed = widget.isCollapsed;

    final sidebarBg = AppColors.sidebarBackground(brightness);
    final sidebarFg = AppColors.sidebarForeground(brightness);
    final sidebarPrimary = brightness == Brightness.light
        ? AppColors.lightSidebarPrimary
        : AppColors.darkSidebarPrimary;

    final width = isCollapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarExpandedWidth;

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      width: width,
      color: sidebarBg,
      child: Column(
        children: [
          // ─── Header with toggle ───
          _buildHeader(context, sidebarFg, isCollapsed, loc),

          const Divider(height: 1),

          // ─── Navigation items ───
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: studentNavItems.length,
              itemBuilder: (context, index) {
                final item = studentNavItems[index];
                final isActive = _isItemActive(item.route, widget.activeRoute);

                return _SidebarNavItem(
                  item: item,
                  isActive: isActive,
                  isCollapsed: isCollapsed,
                  accentColor: sidebarPrimary,
                  foregroundColor: sidebarFg,
                  onTap: () => widget.onNavigate(item.route),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ─── User info at bottom ───
          _buildUserInfo(context, sidebarFg, isCollapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color fgColor,
    bool isCollapsed,
    AppLocalizations loc,
  ) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (!isCollapsed) ...[
              Icon(
                Icons.school_rounded,
                color: fgColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            IconButton(
              icon: Icon(
                isCollapsed
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: fgColor,
                size: 20,
              ),
              onPressed: widget.onToggleCollapse,
              tooltip: isCollapsed
                  ? loc.t('nav.sheetTitle')
                  : loc.t('nav.collapseSidebar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    Color fgColor,
    bool isCollapsed,
  ) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: isCollapsed
          ? CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.t('roles.student'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.userId ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fgColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  bool _isItemActive(String route, String activeRoute) {
    if (route == '/student/dashboard' && activeRoute == '/student/dashboard') {
      return true;
    }
    return activeRoute.startsWith(route) && route != '/student/dashboard';
  }
}

/// Single navigation item in the sidebar.
class _SidebarNavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final bool isCollapsed;
  final Color accentColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.accentColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    if (isCollapsed) {
      return Tooltip(
        message: item.labelBuilder(loc),
        preferBelow: false,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(
            isActive ? (item.activeIcon ?? item.icon) : item.icon,
            color:
                isActive ? accentColor : foregroundColor.withValues(alpha: 0.7),
            size: 22,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    return ListTile(
      leading: Icon(
        isActive ? (item.activeIcon ?? item.icon) : item.icon,
        color: isActive ? accentColor : foregroundColor.withValues(alpha: 0.7),
        size: 22,
      ),
      title: Text(
        item.labelBuilder(loc),
        style: theme.textTheme.bodyMedium?.copyWith(
          color:
              isActive ? accentColor : foregroundColor.withValues(alpha: 0.7),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isActive,
      selectedTileColor: accentColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
      onTap: onTap,
    );
  }
}

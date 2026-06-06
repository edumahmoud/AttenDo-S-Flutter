import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';
import '../../config/routes/route_guards.dart';
import '../shared/app_header.dart';
import '../shared/app_sidebar.dart';
import '../shared/mobile_bottom_nav.dart';

/// Main student dashboard shell.
///
/// This is the MOST IMPORTANT layout widget:
/// - AppBar at top with sidebar toggle, section title, notification bell,
///   theme toggle, and user avatar dropdown
/// - Sidebar on left (LTR) or right (RTL) with collapsed/expanded states
/// - Bottom navigation bar (mobile only) with 5 items
/// - Content area in the middle
/// - Full RTL support throughout
class StudentShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const StudentShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  bool _sidebarCollapsed = true;
  final int _notificationCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Get the current active route path.
  String get _currentRoute {
    final location = GoRouterState.of(context).matchedLocation;
    return location;
  }

  /// Get the current section title based on active route.
  String _getSectionTitle(AppLocalizations loc) {
    final route = _currentRoute;
    for (final item in studentNavItems) {
      if (route.startsWith(item.route)) {
        return item.labelBuilder(loc);
      }
    }
    return loc.navDashboard;
  }

  /// Map current route to bottom nav index.
  int get _bottomNavIndex {
    final route = _currentRoute;
    if (route.startsWith('/student/subjects')) return 0;
    if (route.startsWith('/student/notifications')) return 1;
    if (route.startsWith('/student/dashboard')) return 2;
    if (route.startsWith('/student/files')) return 3;
    return 4; // More
  }

  bool get _isDesktop {
    return MediaQuery.sizeOf(context).width >= 1024;
  }

  bool get _isTablet {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 768 && width < 1024;
  }

  bool get _isMobile {
    return MediaQuery.sizeOf(context).width < 768;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Directionality(
      textDirection: loc.textDirection,
      child: _isMobile
          ? _buildMobileLayout(context, loc)
          : _buildDesktopLayout(context, loc),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Desktop / Tablet Layout
  // ────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations loc) {
    final isRTL = loc.isRTL;
    final showSidebar = _isDesktop || (_isTablet && !_sidebarCollapsed);

    final sidebar = _buildSidebar(loc);
    final content = _buildContentWithHeader(loc);

    return Scaffold(
      body: Row(
        children: [
          if (showSidebar) ...[
            if (isRTL) content else sidebar,
          ],
          if (isRTL) sidebar else content,
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations loc) {
    return AppSidebar(
      activeRoute: _currentRoute,
      onNavigate: (route) {
        context.go(route);
      },
      isCollapsed: _sidebarCollapsed,
      onToggleCollapse: () {
        setState(() {
          _sidebarCollapsed = !_sidebarCollapsed;
        });
      },
    );
  }

  Widget _buildContentWithHeader(AppLocalizations loc) {
    return Expanded(
      child: Column(
        children: [
          // ─── App Header ───
          AppHeader(
            title: _getSectionTitle(loc),
            onMenuTap: _isTablet
                ? () {
                    setState(() {
                      _sidebarCollapsed = !_sidebarCollapsed;
                    });
                  }
                : null,
            notificationCount: _notificationCount,
            showSearch: true,
          ),

          // ─── Content ───
          Expanded(
            child: widget.navigationShell,
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Mobile Layout
  // ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppConstants.headerHeight),
        child: AppHeader(
          title: _getSectionTitle(loc),
          onMenuTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          notificationCount: _notificationCount,
        ),
      ),
      drawer: _buildMobileDrawer(loc, theme, brightness),
      body: widget.navigationShell,
      bottomNavigationBar: MobileBottomNav(
        currentIndex: _bottomNavIndex,
        onDestinationSelected: (index) {
          _handleBottomNavTap(index);
        },
        onMoreTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        notificationCount: _notificationCount,
      ),
    );
  }

  Widget _buildMobileDrawer(
    AppLocalizations loc,
    ThemeData theme,
    Brightness brightness,
  ) {
    final sidebarBg = AppColors.sidebarBackground(brightness);
    final sidebarFg = AppColors.sidebarForeground(brightness);

    return Drawer(
      backgroundColor: sidebarBg,
      child: Column(
        children: [
          // ─── Drawer header ───
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.ocean(brightness),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ─── Navigation items ───
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: studentNavItems.length,
              itemBuilder: (context, index) {
                final item = studentNavItems[index];
                final isActive = _currentRoute.startsWith(item.route);

                return ListTile(
                  leading: Icon(
                    isActive ? (item.activeIcon ?? item.icon) : item.icon,
                    color: isActive
                        ? AppColors.lightSidebarPrimary
                        : sidebarFg.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  title: Text(
                    item.labelBuilder(loc),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? AppColors.lightSidebarPrimary
                          : sidebarFg.withValues(alpha: 0.7),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isActive,
                  selectedTileColor:
                      AppColors.lightSidebarAccent.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    context.go(item.route);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ─── User info at bottom ───
          _buildDrawerUserInfo(theme, sidebarFg, loc),
        ],
      ),
    );
  }

  Widget _buildDrawerUserInfo(
    ThemeData theme,
    Color fgColor,
    AppLocalizations loc,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
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
                ),
                Text(
                  loc.appTagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fgColor.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: fgColor.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: () {
              ref.read(authStateProvider.notifier).state = const AuthState(
                isAuthenticated: false,
                userRole: null,
                userId: null,
              );
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0: // Subjects
        context.go('/student/subjects');
        break;
      case 1: // Notifications
        context.go('/student/notifications');
        break;
      case 2: // Dashboard
        widget.navigationShell.goBranch(
          0,
          initialLocation: widget.navigationShell.currentIndex == 0,
        );
        break;
      case 3: // Files
        context.go('/student/files');
        break;
      case 4: // More
        _scaffoldKey.currentState?.openDrawer();
        break;
    }
  }
}

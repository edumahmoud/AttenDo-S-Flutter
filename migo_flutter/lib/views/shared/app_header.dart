import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';
import '../../config/routes/route_guards.dart';

/// Shared header component with logo/title, optional search,
/// notification bell with count badge, theme toggle, and user menu.
class AppHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final int notificationCount;
  final bool showSearch;

  const AppHeader({
    super.key,
    required this.title,
    this.onMenuTap,
    this.notificationCount = 0,
    this.showSearch = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final loc = AppLocalizations.of(context);
    final oceanColor = AppColors.ocean(brightness);
    final oceanFg = AppColors.oceanForeground(brightness);

    return Container(
      height: AppConstants.headerHeight,
      decoration: BoxDecoration(
        color: oceanColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // ─── Menu toggle ───
            if (onMenuTap != null)
              IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: oceanFg,
                  size: 22,
                ),
                onPressed: onMenuTap,
                tooltip: loc.t('header.openMenu'),
              ),

            // ─── Title ───
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: oceanFg,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ─── Search (optional) ───
            if (showSearch)
              IconButton(
                icon: Icon(
                  Icons.search_rounded,
                  color: oceanFg,
                  size: 22,
                ),
                onPressed: () {
                  // TODO: Open search
                },
                tooltip: loc.commonSearch,
              ),

            // ─── Notification bell ───
            _NotificationBell(
              count: notificationCount,
              color: oceanFg,
              onTap: () {
                // TODO: Navigate to notifications
              },
            ),

            // ─── Theme toggle ───
            IconButton(
              icon: Icon(
                brightness == Brightness.light
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_rounded,
                color: oceanFg,
                size: 22,
              ),
              onPressed: () {
                final current = ref.read(themeModeProvider);
                ref.read(themeModeProvider.notifier).state =
                    current == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light;
              },
              tooltip: brightness == Brightness.light ? 'Dark mode' : 'Light mode',
            ),

            // ─── User avatar dropdown ───
            _UserMenu(oceanFg: oceanFg),
          ],
        ),
      ),
    );
  }
}

/// Notification bell with badge.
class _NotificationBell extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: color,
            size: 22,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '${count > 99 ? '99+' : count}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: onTap,
    );
  }
}

/// User avatar dropdown menu.
class _UserMenu extends ConsumerWidget {
  final Color oceanFg;

  const _UserMenu({required this.oceanFg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusGeometry,
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: oceanFg.withValues(alpha: 0.2),
        child: Icon(
          Icons.person_rounded,
          size: 18,
          color: oceanFg,
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            // TODO: Navigate to profile
            break;
          case 'settings':
            // TODO: Navigate to settings
            break;
          case 'signout':
            ref.read(authStateProvider.notifier).state = const AuthState(
              isAuthenticated: false,
              userRole: null,
              userId: null,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18),
              const SizedBox(width: 10),
              Text(loc.t('header.profile')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 10),
              Text(loc.t('header.settings')),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Text(
                loc.t('header.signOut'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

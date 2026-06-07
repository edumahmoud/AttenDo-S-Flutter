import 'package:flutter/material.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';

/// Mobile bottom navigation bar with 5 items.
///
/// Items: Subjects, Notifications, Dashboard (center floating),
/// Files, More.
class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onMoreTap;
  final int notificationCount;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.onMoreTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    // Map our 5 positions: 0=Subjects, 1=Notifications, 2=Dashboard, 3=Files, 4=More
    return Container(
      height: AppConstants.bottomNavHeight,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Subjects
          _NavItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: loc.navSubjects,
            isActive: currentIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),

          // Notifications
          _NavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: loc.navNotifications,
            isActive: currentIndex == 1,
            badge: notificationCount > 0 ? notificationCount : null,
            onTap: () => onDestinationSelected(1),
          ),

          // Dashboard (center floating)
          _FloatingCenterButton(
            icon: Icons.dashboard_rounded,
            label: loc.navDashboard,
            isActive: currentIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),

          // Files
          _NavItem(
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder_rounded,
            label: loc.navFiles,
            isActive: currentIndex == 3,
            onTap: () => onDestinationSelected(3),
          ),

          // More
          _NavItem(
            icon: Icons.more_horiz_rounded,
            activeIcon: Icons.more_horiz_rounded,
            label: loc.t('common.more'),
            isActive: currentIndex == 4,
            onTap: onMoreTap ?? () => onDestinationSelected(4),
          ),
        ],
      ),
    );
  }
}

/// Standard nav item with optional badge.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 22,
                      color: color,
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${badge! > 99 ? '99+' : badge}',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating center dashboard button.
class _FloatingCenterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingCenterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? colorScheme.onPrimary : colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../i18n/app_localizations.dart';
import '../../config/constants/app_constants.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';

// ────────────────────────────────────────────────────────────────
// Settings Screen
// ────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Preference toggles (local state)
  bool _notificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _landscapeLockEnabled = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settingsState = ref.watch(settingsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            // No explicit refresh needed; state is reactive
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                _buildHeader(loc, theme),

                // ─── Profile Section ───
                _buildProfileSection(loc, theme, user),

                const SizedBox(height: 8),

                // ─── Account Section ───
                _buildAccountSection(loc, theme, settingsState),

                const SizedBox(height: 8),

                // ─── Preferences Section ───
                _buildPreferencesSection(loc, theme),

                const SizedBox(height: 8),

                // ─── Danger Zone ───
                _buildDangerZone(loc, theme, settingsState),

                const SizedBox(height: 8),

                // ─── About Section ───
                _buildAboutSection(loc, theme),

                // ─── Sign Out ───
                _buildSignOutButton(loc, theme),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('settings.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.t('settings.subtitle'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Section ───

  Widget _buildProfileSection(
      AppLocalizations loc, ThemeData theme, UserProfile? user) {
    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            loc.t('settings.profile.title'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Avatar with edit button
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor:
                    theme.colorScheme.primaryContainer,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!) as ImageProvider
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        user?.name.isNotEmpty == true
                            ? user!.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned.directional(
                textDirection: loc.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                bottom: 0,
                end: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.cardColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Name
        _ProfileField(
          icon: Icons.person_rounded,
          label: loc.t('settings.profile.nameLabel'),
          value: user?.name ?? '',
          onEdit: () => _showEditNameDialog(loc, user),
        ),

        // Email
        _ProfileField(
          icon: Icons.email_rounded,
          label: loc.t('settings.profile.emailLabel'),
          value: user?.email ?? '',
          readOnly: true,
          readOnlyHint: loc.t('settings.profile.emailReadonly'),
        ),

        // Role badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.badge_rounded,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                loc.t('settings.profile.roleLabel'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightOcean.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.t('roles.student'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.lightOcean,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Account Section ───

  Widget _buildAccountSection(
      AppLocalizations loc, ThemeData theme, SettingsState settingsState) {
    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            loc.t('settings.accountSection'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Change Password
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: loc.t('settings.changePassword'),
          onTap: () => _showChangePasswordDialog(loc, settingsState),
        ),

        // Change Language
        _SettingsTile(
          icon: Icons.language_rounded,
          title: loc.t('settings.changeLanguage'),
          trailing: Text(
            settingsState.locale == 'ar'
                ? loc.t('settings.arabic')
                : loc.t('settings.english'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => _showLanguageDialog(loc, settingsState),
        ),

        // Change Theme
        _SettingsTile(
          icon: Icons.palette_rounded,
          title: loc.t('settings.changeTheme'),
          trailing: Text(
            _themeLabel(loc, settingsState.themeMode),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => _showThemeDialog(loc, settingsState),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Preferences Section ───

  Widget _buildPreferencesSection(AppLocalizations loc, ThemeData theme) {
    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            loc.t('settings.preferencesSection'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _SwitchTile(
          icon: Icons.notifications_rounded,
          title: loc.t('settings.notificationsPref'),
          subtitle: loc.t('settings.notificationsPrefDesc'),
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _SwitchTile(
          icon: Icons.push_pin_rounded,
          title: loc.t('settings.pushNotifications'),
          subtitle: loc.t('settings.pushNotificationsDesc'),
          value: _pushNotificationsEnabled,
          onChanged: (v) =>
              setState(() => _pushNotificationsEnabled = v),
        ),
        _SwitchTile(
          icon: Icons.volume_up_rounded,
          title: loc.t('settings.soundPref'),
          subtitle: loc.t('settings.soundPrefDesc'),
          value: _soundEnabled,
          onChanged: (v) => setState(() => _soundEnabled = v),
        ),
        _SwitchTile(
          icon: Icons.vibration_rounded,
          title: loc.t('settings.vibrationPref'),
          subtitle: loc.t('settings.vibrationPrefDesc'),
          value: _vibrationEnabled,
          onChanged: (v) => setState(() => _vibrationEnabled = v),
        ),
        _SwitchTile(
          icon: Icons.screen_lock_rotation_rounded,
          title: loc.t('settings.landscapeLock'),
          subtitle: loc.t('settings.landscapeLockDesc'),
          value: _landscapeLockEnabled,
          onChanged: (v) =>
              setState(() => _landscapeLockEnabled = v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Danger Zone ───

  Widget _buildDangerZone(
      AppLocalizations loc, ThemeData theme, SettingsState settingsState) {
    return _SectionCard(
      borderColor: AppColors.lightDestructive.withValues(alpha: 0.3),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            loc.t('settings.danger.title'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.lightDestructive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            loc.t('settings.danger.deleteDesc'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: settingsState.isDeletingAccount
                  ? null
                  : () => _showDeleteAccountDialog(loc, settingsState),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text(loc.t('settings.danger.deleteButton')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lightDestructive,
                side: BorderSide(color: AppColors.lightDestructive),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusGeometry,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── About Section ───

  Widget _buildAboutSection(AppLocalizations loc, ThemeData theme) {
    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            loc.t('settings.aboutSection'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _SettingsTile(
          icon: Icons.info_rounded,
          title: loc.t('settings.appVersion'),
          trailing: Text(
            AppConstants.appVersion,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.description_rounded,
          title: loc.t('settings.termsOfService'),
          onTap: () => _launchUrl('https://attendo.app/terms'),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: loc.t('settings.privacyPolicy'),
          onTap: () => _launchUrl('https://attendo.app/privacy'),
        ),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: loc.t('settings.support'),
          onTap: () => _launchUrl('https://attendo.app/support'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Sign Out ───

  Widget _buildSignOutButton(AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(loc),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(loc.t('settings.signOut')),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  String _themeLabel(AppLocalizations loc, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return loc.t('settings.themeLight');
      case ThemeMode.dark:
        return loc.t('settings.themeDark');
      case ThemeMode.system:
        return loc.t('settings.themeSystem');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── Edit Name Dialog ───

  void _showEditNameDialog(AppLocalizations loc, UserProfile? user) {
    final controller = TextEditingController(text: user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(settingsControllerProvider);
          return AlertDialog(
            title: Text(loc.t('settings.profile.nameLabel')),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: loc.t('settings.profile.namePlaceholder'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.commonCancel),
              ),
              ElevatedButton(
                onPressed: state.isUpdatingProfile
                    ? null
                    : () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) return;
                        final success = await ref
                            .read(settingsControllerProvider.notifier)
                            .updateProfile({'name': newName});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.t('common.toastUpdated'))),
                            );
                          }
                        }
                      },
                child: state.isUpdatingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.commonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Change Password Dialog ───

  void _showChangePasswordDialog(
      AppLocalizations loc, SettingsState settingsState) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(settingsControllerProvider);
          return Directionality(
            textDirection: loc.textDirection,
            child: AlertDialog(
              title: Text(loc.t('settings.password.title')),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                loc.t('settings.password.currentLabel'),
                            hintText: loc
                                .t('settings.password.currentPlaceholder'),
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? loc.t(
                                  'settings.password.errorCurrentRequired')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                loc.t('settings.password.newLabel'),
                            hintText:
                                loc.t('settings.password.newPlaceholder'),
                            prefixIcon:
                                const Icon(Icons.lock_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return loc.t(
                                  'settings.password.errorNewRequired');
                            }
                            if (v.length < 6) {
                              return loc.t(
                                  'settings.password.errorNewMinLength');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                loc.t('settings.password.confirmLabel'),
                            hintText: loc
                                .t('settings.password.confirmPlaceholder'),
                            prefixIcon:
                                const Icon(Icons.lock_rounded),
                          ),
                          validator: (v) {
                            if (v != newController.text) {
                              return loc.t(
                                  'settings.password.errorMismatch');
                            }
                            return null;
                          },
                        ),
                        if (state.passwordError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.passwordError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12),
                          ),
                        ],
                        if (state.successMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.successMessage!,
                            style: TextStyle(
                                color: AppColors.lightTealAccent,
                                fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: state.isChangingPassword
                      ? null
                      : () => Navigator.pop(ctx),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: state.isChangingPassword
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final success = await ref
                              .read(settingsControllerProvider.notifier)
                              .changePassword(
                                currentController.text,
                                newController.text,
                              );
                          if (ctx.mounted && success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.t(
                                      'settings.password.successChanged'))),
                            );
                          }
                        },
                  child: state.isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('settings.password.submit')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Language Dialog ───

  void _showLanguageDialog(
      AppLocalizations loc, SettingsState settingsState) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(settingsControllerProvider);
          return SimpleDialog(
            title: Text(loc.t('settings.changeLanguage')),
            children: [
              SimpleDialogOption(
                onPressed: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .changeLocale('ar');
                  ref.read(localeProvider.notifier).state =
                      const Locale('ar');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'ar',
                      groupValue: state.locale,
                      onChanged: (v) async {
                        if (v != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .changeLocale(v);
                          ref.read(localeProvider.notifier).state =
                              Locale(v);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.t('settings.arabic'))),
                    const Text('العربية',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .changeLocale('en');
                  ref.read(localeProvider.notifier).state =
                      const Locale('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'en',
                      groupValue: state.locale,
                      onChanged: (v) async {
                        if (v != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .changeLocale(v);
                          ref.read(localeProvider.notifier).state =
                              Locale(v);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.t('settings.english'))),
                    const Text('English',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Theme Dialog ───

  void _showThemeDialog(
      AppLocalizations loc, SettingsState settingsState) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(settingsControllerProvider);
          return SimpleDialog(
            title: Text(loc.t('settings.changeTheme')),
            children: [
              SimpleDialogOption(
                onPressed: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .changeTheme(ThemeMode.light);
                  ref.read(themeModeProvider.notifier).state =
                      ThemeMode.light;
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: state.themeMode,
                      onChanged: (v) async {
                        if (v != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .changeTheme(v);
                          ref.read(themeModeProvider.notifier).state =
                              v;
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.t('settings.themeLight'))),
                    const Icon(Icons.light_mode_rounded, size: 20),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .changeTheme(ThemeMode.dark);
                  ref.read(themeModeProvider.notifier).state =
                      ThemeMode.dark;
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: state.themeMode,
                      onChanged: (v) async {
                        if (v != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .changeTheme(v);
                          ref.read(themeModeProvider.notifier).state =
                              v;
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.t('settings.themeDark'))),
                    const Icon(Icons.dark_mode_rounded, size: 20),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .changeTheme(ThemeMode.system);
                  ref.read(themeModeProvider.notifier).state =
                      ThemeMode.system;
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Row(
                  children: [
                    Radio<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: state.themeMode,
                      onChanged: (v) async {
                        if (v != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .changeTheme(v);
                          ref.read(themeModeProvider.notifier).state =
                              v;
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(loc.t('settings.themeSystem'))),
                    const Icon(Icons.settings_brightness_rounded,
                        size: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Delete Account Dialog ───

  void _showDeleteAccountDialog(
      AppLocalizations loc, SettingsState settingsState) {
    final deleteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(settingsControllerProvider);
          return Directionality(
            textDirection: loc.textDirection,
            child: AlertDialog(
              title: Text(loc.t('settings.danger.confirmTitle')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.t('settings.danger.confirmDesc')),
                  const SizedBox(height: 16),
                  Text(
                    loc.t('settings.profile.deleteTypeHint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deleteController,
                    decoration: InputDecoration(
                      hintText: loc.t('settings.profile.deletePlaceholder'),
                      prefixIcon: const Icon(Icons.warning_amber_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: state.isDeletingAccount
                      ? null
                      : () => Navigator.pop(ctx),
                  child: Text(loc.t('settings.danger.confirmCancel')),
                ),
                ElevatedButton(
                  onPressed: state.isDeletingAccount
                      ? null
                      : () async {
                          // Verify user typed DELETE
                          final typed = deleteController.text.trim();
                          if (typed.toUpperCase() != 'DELETE' &&
                              typed != 'حذف') {
                            return;
                          }
                          final success = await ref
                              .read(settingsControllerProvider.notifier)
                              .deleteAccount();
                          if (ctx.mounted && success) {
                            Navigator.pop(ctx);
                            // Sign out after deletion
                            ref.read(authControllerProvider.notifier).signOut();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: state.isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(loc.t('settings.danger.confirmDelete')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Sign Out Dialog ───

  void _showSignOutDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(authControllerProvider);
          return AlertDialog(
            title: Text(loc.t('settings.signOut')),
            content: Text(loc.t('settings.signOutConfirm')),
            actions: [
              TextButton(
                onPressed:
                    state.isLoading ? null : () => Navigator.pop(ctx),
                child: Text(loc.commonCancel),
              ),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref.read(authControllerProvider.notifier).signOut();
                        Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(loc.t('settings.signOut')),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Reusable Widgets
// ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ))
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool readOnly;
  final String? readOnlyHint;
  final VoidCallback? onEdit;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.readOnly = false,
    this.readOnlyHint,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isEmpty ? '--' : value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (readOnly && readOnlyHint != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          readOnlyHint!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null && !readOnly)
            IconButton(
              icon: Icon(Icons.edit_rounded,
                  size: 18, color: theme.colorScheme.primary),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

// ─── Settings State ───

class SettingsState {
  final ThemeMode themeMode;
  final String locale;
  final bool isUpdatingProfile;
  final bool isChangingPassword;
  final bool isDeletingAccount;
  final String? profileError;
  final String? passwordError;
  final String? deleteError;
  final String? successMessage;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = 'ar',
    this.isUpdatingProfile = false,
    this.isChangingPassword = false,
    this.isDeletingAccount = false,
    this.profileError,
    this.passwordError,
    this.deleteError,
    this.successMessage,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? isUpdatingProfile,
    bool? isChangingPassword,
    bool? isDeletingAccount,
    String? profileError,
    String? passwordError,
    String? deleteError,
    String? successMessage,
    bool clearProfileError = false,
    bool clearPasswordError = false,
    bool clearDeleteError = false,
    bool clearSuccessMessage = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      profileError:
          clearProfileError ? null : (profileError ?? this.profileError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      deleteError:
          clearDeleteError ? null : (deleteError ?? this.deleteError),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Settings Controller ───

class SettingsController extends StateNotifier<SettingsState> {
  final AuthService _authService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;

  SettingsController(
    this._authService,
    this._storageService,
    this._supabaseService,
  ) : super(const SettingsState()) {
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final savedTheme = _storageService.getThemeMode();
    final savedLocale = _storageService.getLocale();

    ThemeMode themeMode = ThemeMode.system;
    if (savedTheme == 'light') themeMode = ThemeMode.light;
    if (savedTheme == 'dark') themeMode = ThemeMode.dark;

    state = state.copyWith(
      themeMode: themeMode,
      locale: savedLocale ?? 'ar',
    );
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(
      isUpdatingProfile: true,
      clearProfileError: true,
      clearSuccessMessage: true,
    );
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabaseService.client
          .from('profiles')
          .update(data)
          .eq('id', userId);

      state = state.copyWith(
        isUpdatingProfile: false,
        successMessage: 'Profile updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingProfile: false,
        profileError: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(
      isChangingPassword: true,
      clearPasswordError: true,
      clearSuccessMessage: true,
    );
    try {
      // Verify current password by re-authenticating
      final email = _supabaseService.currentUser?.email;
      if (email == null) throw Exception('Not authenticated');

      await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update password
      await _authService.changePassword(newPassword);

      state = state.copyWith(
        isChangingPassword: false,
        successMessage: 'Password changed successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        passwordError: _friendlyError(e),
      );
      return false;
    }
  }

  Future<void> changeTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final modeString = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storageService.saveThemeMode(modeString);
  }

  Future<void> changeLocale(String localeCode) async {
    state = state.copyWith(locale: localeCode);
    await _storageService.saveLocale(localeCode);
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(
      isDeletingAccount: true,
      clearDeleteError: true,
    );
    try {
      await _authService.deleteAccount();
      await _storageService.clearAll();
      state = state.copyWith(isDeletingAccount: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeletingAccount: false,
        deleteError: _friendlyError(e),
      );
      return false;
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login') || msg.contains('wrong password')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred. Please try again.';
  }
}

// ─── Provider ───

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(
    ref.watch(authServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

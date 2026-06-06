import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants/app_constants.dart';

class StorageService {
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize both SharedPreferences and FlutterSecureStorage.
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  // ===========================================================================
  // Auth Data (Secure Storage)
  // ===========================================================================

  /// Persist authentication data securely.
  Future<void> saveAuthData(Map<String, dynamic> data) async {
    _ensureInitialized();
    await _secureStorage.write(
      key: AppConstants.authDataKey,
      value: jsonEncode(data),
    );
  }

  /// Retrieve stored authentication data, or null if not found.
  Future<Map<String, dynamic>?> getAuthData() async {
    _ensureInitialized();
    final raw = await _secureStorage.read(key: AppConstants.authDataKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear all stored authentication data.
  Future<void> clearAuthData() async {
    _ensureInitialized();
    await _secureStorage.delete(key: AppConstants.authDataKey);
  }

  // ===========================================================================
  // Locale (Shared Preferences)
  // ===========================================================================

  /// Save the user's preferred locale.
  Future<bool> saveLocale(String locale) async {
    _ensureInitialized();
    return _prefs.setString(AppConstants.localeKey, locale);
  }

  /// Get the user's preferred locale, or null if not set.
  String? getLocale() {
    _ensureInitialized();
    return _prefs.getString(AppConstants.localeKey);
  }

  // ===========================================================================
  // Theme Mode (Shared Preferences)
  // ===========================================================================

  /// Save the theme mode string (e.g., "light", "dark", "system").
  Future<bool> saveThemeMode(String mode) async {
    _ensureInitialized();
    return _prefs.setString(AppConstants.themeModeKey, mode);
  }

  /// Get the saved theme mode, or null if not set.
  String? getThemeMode() {
    _ensureInitialized();
    return _prefs.getString(AppConstants.themeModeKey);
  }

  // ===========================================================================
  // Generic Key-Value (Shared Preferences)
  // ===========================================================================

  /// Save a string value for the given key.
  Future<bool> saveString(String key, String value) async {
    _ensureInitialized();
    return _prefs.setString(key, value);
  }

  /// Get a string value for the given key, or null if not set.
  String? getString(String key) {
    _ensureInitialized();
    return _prefs.getString(key);
  }

  /// Save an integer value for the given key.
  Future<bool> saveInt(String key, int value) async {
    _ensureInitialized();
    return _prefs.setInt(key, value);
  }

  /// Get an integer value for the given key, or null if not set.
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs.getInt(key);
  }

  // ===========================================================================
  // Secure Generic Helpers
  // ===========================================================================

  /// Save a string value securely.
  Future<void> saveSecureString(String key, String value) async {
    _ensureInitialized();
    await _secureStorage.write(key: key, value: value);
  }

  /// Get a string value from secure storage.
  Future<String?> getSecureString(String key) async {
    _ensureInitialized();
    return _secureStorage.read(key: key);
  }

  /// Delete a value from secure storage.
  Future<void> deleteSecureString(String key) async {
    _ensureInitialized();
    await _secureStorage.delete(key: key);
  }

  // ===========================================================================
  // Bulk Clear
  // ===========================================================================

  /// Clear all SharedPreferences and secure storage data.
  Future<void> clearAll() async {
    _ensureInitialized();
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Async provider that resolves once StorageService is initialized.
final storageInitializedProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(storageServiceProvider);
  await service.initialize();
});

/// Async provider for the saved locale preference.
final localeProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.getLocale();
});

/// Async provider for the saved theme mode preference.
final themeModeProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.getThemeMode();
});

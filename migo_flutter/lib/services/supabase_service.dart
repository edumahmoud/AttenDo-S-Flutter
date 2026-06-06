import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  bool _initialized = false;

  /// Initialize Supabase with project URL and anon key.
  /// Must be called once in main() before runApp().
  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// The active Supabase client instance.
  SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseService not initialized. Call initialize() first.',
      );
    }
    return _client;
  }

  /// Current authenticated user, or null if not signed in.
  User? get currentUser => _client.auth.currentUser;

  /// Current auth session, or null if not signed in.
  Session? get currentSession => _client.auth.currentSession;

  /// Build authorization headers from the current session token.
  /// Useful for REST API calls that need the Supabase JWT.
  Map<String, String> getAuthHeaders() {
    final session = currentSession;
    if (session == null) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': AppConstants.supabaseAnonKey,
    };
  }

  /// Refresh the current session and return the new access token.
  Future<String?> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      return response.session?.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Stream of auth state changes (signedIn, signedOut, etc.).
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Check if the service has been initialized.
  bool get isInitialized => _initialized;
}

/// Riverpod provider for [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Riverpod provider for the raw [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return ref.watch(supabaseServiceProvider).client;
});

/// Riverpod provider that exposes the current auth user (reactive).
final authUserProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.onAuthStateChange.map((state) => state.session?.user);
});

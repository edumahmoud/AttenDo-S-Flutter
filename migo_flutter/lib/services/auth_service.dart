import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabaseService;

  AuthService(this._supabaseService);

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------

  /// Sign in with email and password.
  /// Returns the [UserProfile] on success.
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return await _fetchUserProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Up
  // ---------------------------------------------------------------------------

  /// Sign up with email, password, and display name.
  /// Returns the [UserProfile] on success.
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': 'student'},
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure(message: 'Sign up failed – no user returned.');
      }
      // Wait for the profile row to be available (trigger-created)
      return await _fetchUserProfile(user.id);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Sign in with Google OAuth.
  /// Requires Google OAuth to be configured in the Supabase dashboard.
  Future<UserProfile> signInWithGoogle() async {
    try {
      await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${AppConstants.appName}://auth/callback',
      );
      // After OAuth redirect the user should be available in the session.
      final user = _supabaseService.currentUser;
      if (user == null) {
        throw const AuthFailure(
          message: 'Google sign-in failed – no user returned.',
        );
      }
      return await _fetchUserProfile(user.id);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Sign the current user out.
  Future<void> signOut() async {
    try {
      await _supabaseService.client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Current User / Session
  // ---------------------------------------------------------------------------

  /// Return the cached [UserProfile] for the current user, or null.
  Future<UserProfile?> getCurrentUser() async {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  /// Return the current Supabase [Session], or null.
  Session? getCurrentSession() => _supabaseService.currentSession;

  /// Stream of auth state changes.
  Stream<AuthState> onAuthStateChange() =>
      _supabaseService.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Password Management
  // ---------------------------------------------------------------------------

  /// Change the password for the currently signed-in user.
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  /// Send a password-reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Account Deletion
  // ---------------------------------------------------------------------------

  /// Delete the current user's account.
  /// This calls a Supabase RPC function that handles cascade deletion.
  Future<void> deleteAccount() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'No authenticated user.');
      }
      await _supabaseService.client.rpc('delete_user_account');
      await signOut();
    } on PostgrestException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  Future<UserProfile> _fetchUserProfile(String userId) async {
    final data = await _supabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(data);
  }
}

// ---------------------------------------------------------------------------
// Custom Exception
// ---------------------------------------------------------------------------

class AuthFailure implements Exception {
  final String message;
  final String? code;

  const AuthFailure({required this.message, this.code});

  @override
  String toString() => 'AuthFailure($code): $message';
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseServiceProvider));
});

/// Reactive provider that resolves to the current [UserProfile] or null.
final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

/// Stream provider for auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.onAuthStateChange();
});

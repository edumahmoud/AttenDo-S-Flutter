import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../models/models.dart';
import '../services/services.dart';

// ─── Auth Controller State ───
// Named AuthControllerState to avoid conflict with
// Supabase's AuthState from supabase_flutter.

class AuthControllerState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthControllerState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthControllerState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthControllerState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ─── Auth Controller ───

class AuthController extends StateNotifier<AuthControllerState> {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthController(this._authService)
      : super(const AuthControllerState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthControllerState(user: user, isAuthenticated: true);
      } else {
        state = const AuthControllerState();
      }
      // Listen to auth state changes from Supabase
      _authStateSubscription = _authService.onAuthStateChange().listen((_) {
        _refreshUser();
      });
    } catch (e) {
      state = AuthControllerState(error: _friendlyError(e));
    }
  }

  Future<void> _refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthControllerState(
        user: user,
        isAuthenticated: user != null,
      );
    } catch (_) {
      // Silently ignore refresh errors
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthControllerState(user: user, isAuthenticated: true);
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      state = AuthControllerState(user: user, isAuthenticated: true);
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithGoogle();
      state = AuthControllerState(user: user, isAuthenticated: true);
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      state = const AuthControllerState();
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.changePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

// ─── Provider ───

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

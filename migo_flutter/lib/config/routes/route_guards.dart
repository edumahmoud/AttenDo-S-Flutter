import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

// ─── Auth State Provider ───

/// Provider that tracks the current authentication state.
///
/// Used by route guards and UI widgets that need simple auth state.
/// Named `appAuthStateProvider` to avoid conflict with Supabase's
/// `authStateProvider` (StreamProvider) defined in auth_service.dart.
final appAuthStateProvider = StateProvider<AppAuthState>((ref) => const AppAuthState(
      isAuthenticated: false,
      userRole: null,
      userId: null,
    ));

/// Immutable authentication state for route guards and UI.
class AppAuthState {
  final bool isAuthenticated;
  final String? userRole;
  final String? userId;

  const AppAuthState({
    required this.isAuthenticated,
    this.userRole,
    this.userId,
  });

  bool get isStudent => userRole == AppConstants.roleStudent;

  bool get isTeacher => userRole == AppConstants.roleTeacher;

  bool get isAdmin => userRole == AppConstants.roleAdmin;

  bool get isSuperadmin => userRole == AppConstants.roleSuperadmin;

  AppAuthState copyWith({
    bool? isAuthenticated,
    String? userRole,
    String? userId,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
    );
  }
}

// ─── Route Guards ───

/// Encapsulates route-guard logic for the AttenDo student app.
///
/// Uses Riverpod to check [appAuthStateProvider] and redirects
/// unauthenticated or non-student users accordingly.
class RouteGuards {
  final Ref _ref;

  RouteGuards(this._ref);

  /// Paths that do NOT require authentication.
  static const List<String> publicPaths = [
    '/login',
    '/register',
    '/forgot-password',
  ];

  /// Main guard logic — called by GoRouter's redirect.
  String? guard(BuildContext context, GoRouterState state) {
    final auth = _ref.read(appAuthStateProvider);
    final currentPath = state.matchedLocation;

    final isPublicPath = publicPaths.any(
      (path) => currentPath == path || currentPath.startsWith('$path/'),
    );

    // If user is not authenticated and trying to access a protected route
    if (!auth.isAuthenticated && !isPublicPath) {
      return '/login';
    }

    // If user is authenticated and trying to access auth pages → redirect home
    if (auth.isAuthenticated && isPublicPath) {
      return '/student/dashboard';
    }

    // If authenticated but NOT a student, block student-only routes
    if (auth.isAuthenticated && !auth.isStudent && currentPath.startsWith('/student')) {
      // Could redirect to a teacher/admin dashboard in the future
      return '/login';
    }

    // Allow the navigation
    return null;
  }
}

/// Provider for [RouteGuards] so it can access Riverpod refs.
final routeGuardsProvider = Provider<RouteGuards>((ref) {
  return RouteGuards(ref);
});

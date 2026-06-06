import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/student/student_shell.dart';
import '../../views/student/dashboard_home.dart';
import '../../views/student/subjects_screen.dart';
import '../../views/student/course_page.dart';
import '../../views/student/summaries_screen.dart';
import '../../views/student/tracking_screen.dart';
import '../../views/student/assignments_screen.dart';
import '../../views/student/files_screen.dart';
import '../../views/student/videos_screen.dart';
import '../../views/student/teachers_screen.dart';
import '../../views/student/chat_screen.dart';
import '../../views/student/todos_screen.dart';
import '../../views/student/calendar_screen.dart';
import '../../views/student/reports_screen.dart';
import '../../views/student/notifications_screen.dart';
import '../../views/student/settings_screen.dart';
import '../../views/student/quiz_view_screen.dart';
import 'route_guards.dart';

/// Global navigator keys for the StatefulShellRoute.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The GoRouter instance for the AttenDo student app.
///
/// Supports:
/// - Authentication-based redirects
/// - StatefulShellRoute for bottom navigation persistence
/// - Nested routes under /student
GoRouter appRouter({
  required RouteGuards routeGuards,
  String initialLocation = '/student/dashboard',
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      return routeGuards.guard(context, state);
    },
    routes: [
      // ─── Auth Routes ───
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ─── Student Shell (with bottom navigation) ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardHome(),
              ),
            ],
          ),

          // Branch 1: Subjects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/subjects',
                name: 'subjects',
                builder: (context, state) => const SubjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'course',
                    builder: (context, state) {
                      final courseId = state.pathParameters['id']!;
                      return CoursePage(courseId: courseId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Summaries
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/summaries',
                name: 'summaries',
                builder: (context, state) => const SummariesScreen(),
              ),
            ],
          ),

          // Branch 3: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/chat',
                name: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),

          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Student sub-routes (outside bottom nav shell) ───
      GoRoute(
        path: '/student/tracking',
        name: 'tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/student/assignments',
        name: 'assignments',
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: '/student/files',
        name: 'files',
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        path: '/student/videos',
        name: 'videos',
        builder: (context, state) => const VideosScreen(),
      ),
      GoRoute(
        path: '/student/teachers',
        name: 'teachers',
        builder: (context, state) => const TeachersScreen(),
      ),
      GoRoute(
        path: '/student/todos',
        name: 'todos',
        builder: (context, state) => const TodosScreen(),
      ),
      GoRoute(
        path: '/student/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/student/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/student/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/student/quiz/:id',
        name: 'quiz',
        builder: (context, state) {
          final quizId = state.pathParameters['id']!;
          return QuizViewScreen(quizId: quizId);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error?.message ?? "Unknown"}'),
      ),
    ),
  );
}

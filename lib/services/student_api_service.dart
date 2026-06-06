import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'supabase_service.dart';

class StudentApiService {
  final ApiService _apiService;
  final SupabaseService _supabaseService;

  StudentApiService(this._apiService, this._supabaseService);

  // =========================================================================
  // Summaries (REST API)
  // =========================================================================

  /// Fetch all summaries for the current user.
  Future<List<Summary>> fetchSummaries() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/summaries');
      return (response.data as List<dynamic>)
          .map((json) => Summary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new summary.
  Future<Summary> createSummary(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/summaries',
        data: data,
      );
      return Summary.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a summary by ID.
  Future<void> deleteSummary(String id) async {
    try {
      await _apiService.delete('/api/summaries/$id');
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Quizzes (Supabase direct query)
  // =========================================================================

  /// Fetch quizzes for the current user directly from Supabase.
  Future<List<Quiz>> fetchQuizzes() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('quizzes')
          .select('*, questions:quiz_questions(*)')
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Scores (Supabase direct query)
  // =========================================================================

  /// Fetch scores for the current user directly from Supabase.
  Future<List<Score>> fetchScores() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('scores')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => Score.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Teacher Links (REST API)
  // =========================================================================

  /// Fetch linked teachers via batch user lookup.
  Future<List<UserProfile>> fetchLinkedTeachers() async {
    try {
      final response =
          await _apiService.post<List<dynamic>>('/api/users/batch', data: {});
      return (response.data as List<dynamic>)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Send a teacher link request by teacher code.
  Future<TeacherStudentLink> sendTeacherLink(String teacherCode) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/link-teacher/send',
        data: {'teacher_code': teacherCode},
      );
      return TeacherStudentLink.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Approve a pending teacher link.
  Future<TeacherStudentLink> approveTeacherLink(String linkId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/link-teacher/approve',
        data: {'link_id': linkId},
      );
      return TeacherStudentLink.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a pending teacher link.
  Future<void> cancelTeacherLink(String linkId) async {
    try {
      await _apiService.post(
        '/api/link-teacher/cancel',
        data: {'link_id': linkId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Unlink an already-approved teacher.
  Future<void> unlinkTeacher(String teacherId) async {
    try {
      await _apiService.post(
        '/api/link-teacher/unlink',
        data: {'teacher_id': teacherId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Subjects (REST API)
  // =========================================================================

  /// Join a subject by its code.
  Future<Subject> joinSubject(String code) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/join-subject',
        data: {'code': code},
      );
      return Subject.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Leave a subject by its ID.
  Future<void> leaveSubject(String subjectId) async {
    try {
      await _apiService.post(
        '/api/leave-subject',
        data: {'subject_id': subjectId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Assignments (Supabase direct query)
  // =========================================================================

  /// Fetch assignments for the current user.
  Future<List<Assignment>> fetchAssignments() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('assignments')
          .select('*, subject:subjects(name)')
          .eq('created_by', userId)
          .order('due_date', ascending: true);

      return (data as List<dynamic>)
          .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Submit an assignment.
  Future<Assignment> submitAssignment(Map<String, dynamic> data) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final payload = {...data, 'created_by': userId};
      final result = await _supabaseService.client
          .from('assignments')
          .insert(payload)
          .select()
          .single();

      return Assignment.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Attendance (Supabase direct query)
  // =========================================================================

  /// Fetch attendance sessions for the current user.
  Future<List<AttendanceSession>> fetchAttendance() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('attendance_sessions')
          .select('*, subject:subjects(name), records:attendance_records(*)')
          .eq('teacher_id', userId)
          .order('date', ascending: false)
          .limit(AppConstants.defaultPageSize * 3);

      return (data as List<dynamic>)
          .map(
            (json) => AttendanceSession.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Todos (REST API)
  // =========================================================================

  /// Fetch todos for the current user.
  Future<List<UserTodo>> fetchTodos() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/todos');
      return (response.data as List<dynamic>)
          .map((json) => UserTodo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new todo.
  Future<UserTodo> createTodo(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/todos',
        data: data,
      );
      return UserTodo.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing todo.
  Future<UserTodo> updateTodo(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/todos/$id',
        data: data,
      );
      return UserTodo.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a todo by ID.
  Future<void> deleteTodo(String id) async {
    try {
      await _apiService.delete('/api/todos/$id');
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Notifications (Supabase direct query)
  // =========================================================================

  /// Fetch notifications for the current user.
  Future<List<DBNotification>> fetchNotifications() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(AppConstants.defaultPageSize);

      return (data as List<dynamic>)
          .map(
            (json) => DBNotification.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a notification as read.
  Future<void> markNotificationRead(String id) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Reports (REST API)
  // =========================================================================

  /// Fetch reports for the current user.
  Future<List<Report>> fetchReports() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/api/reports');
      return (response.data as List<dynamic>)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new report.
  Future<Report> createReport(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/reports',
        data: data,
      );
      return Report.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final studentApiServiceProvider = Provider<StudentApiService>((ref) {
  return StudentApiService(
    ref.watch(apiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

/// Async provider that fetches the current user's summaries.
final summariesProvider = FutureProvider<List<Summary>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchSummaries();
});

/// Async provider that fetches the current user's quizzes.
final quizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchQuizzes();
});

/// Async provider that fetches the current user's scores.
final scoresProvider = FutureProvider<List<Score>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchScores();
});

/// Async provider that fetches linked teachers.
final linkedTeachersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchLinkedTeachers();
});

/// Async provider that fetches assignments.
final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchAssignments();
});

/// Async provider that fetches attendance.
final attendanceProvider =
    FutureProvider<List<AttendanceSession>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchAttendance();
});

/// Async provider that fetches todos.
final todosProvider = FutureProvider<List<UserTodo>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchTodos();
});

/// Async provider that fetches notifications.
final notificationsProvider =
    FutureProvider<List<DBNotification>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchNotifications();
});

/// Async provider that fetches reports.
final reportsProvider = FutureProvider<List<Report>>((ref) async {
  final service = ref.watch(studentApiServiceProvider);
  return service.fetchReports();
});

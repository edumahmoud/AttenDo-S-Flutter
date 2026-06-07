import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Dashboard State ───

class DashboardState {
  final List<Summary> summaries;
  final List<Quiz> quizzes;
  final List<Score> scores;
  final List<Assignment> assignments;
  final List<Submission> submissions;
  final List<AttendanceSession> attendance;
  final List<UserProfile> linkedTeachers;
  final int fileCount;

  final bool isLoadingSummaries;
  final bool isLoadingQuizzes;
  final bool isLoadingScores;
  final bool isLoadingAssignments;
  final bool isLoadingAttendance;
  final bool isLoadingTeachers;

  final String? summariesError;
  final String? quizzesError;
  final String? scoresError;
  final String? assignmentsError;
  final String? attendanceError;
  final String? teachersError;

  const DashboardState({
    this.summaries = const [],
    this.quizzes = const [],
    this.scores = const [],
    this.assignments = const [],
    this.submissions = const [],
    this.attendance = const [],
    this.linkedTeachers = const [],
    this.fileCount = 0,
    this.isLoadingSummaries = false,
    this.isLoadingQuizzes = false,
    this.isLoadingScores = false,
    this.isLoadingAssignments = false,
    this.isLoadingAttendance = false,
    this.isLoadingTeachers = false,
    this.summariesError,
    this.quizzesError,
    this.scoresError,
    this.assignmentsError,
    this.attendanceError,
    this.teachersError,
  });

  bool get isAnyLoading =>
      isLoadingSummaries ||
      isLoadingQuizzes ||
      isLoadingScores ||
      isLoadingAssignments ||
      isLoadingAttendance ||
      isLoadingTeachers;

  // ── Computed Stats ──

  int get totalSummaries => summaries.length;

  int get quizCount => quizzes.length;

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.percentage).reduce((a, b) => a + b) /
        scores.length;
  }

  double get attendanceRate {
    if (attendance.isEmpty) return 0;
    int totalRecords = 0;
    int presentRecords = 0;
    for (final session in attendance) {
      final records = session.records ?? [];
      totalRecords += records.length;
      presentRecords += records
          .where((r) =>
              r.status == AttendanceStatus.present ||
              r.status == AttendanceStatus.late)
          .length;
    }
    if (totalRecords == 0) return 0;
    return (presentRecords / totalRecords) * 100;
  }

  int get pendingAssignments => assignments
      .where((a) => a.dueDate != null && a.dueDate!.isAfter(DateTime.now()))
      .length;

  int get teacherCount => linkedTeachers.length;

  DashboardState copyWith({
    List<Summary>? summaries,
    List<Quiz>? quizzes,
    List<Score>? scores,
    List<Assignment>? assignments,
    List<Submission>? submissions,
    List<AttendanceSession>? attendance,
    List<UserProfile>? linkedTeachers,
    int? fileCount,
    bool? isLoadingSummaries,
    bool? isLoadingQuizzes,
    bool? isLoadingScores,
    bool? isLoadingAssignments,
    bool? isLoadingAttendance,
    bool? isLoadingTeachers,
    String? summariesError,
    String? quizzesError,
    String? scoresError,
    String? assignmentsError,
    String? attendanceError,
    String? teachersError,
    bool clearSummariesError = false,
    bool clearQuizzesError = false,
    bool clearScoresError = false,
    bool clearAssignmentsError = false,
    bool clearAttendanceError = false,
    bool clearTeachersError = false,
  }) {
    return DashboardState(
      summaries: summaries ?? this.summaries,
      quizzes: quizzes ?? this.quizzes,
      scores: scores ?? this.scores,
      assignments: assignments ?? this.assignments,
      submissions: submissions ?? this.submissions,
      attendance: attendance ?? this.attendance,
      linkedTeachers: linkedTeachers ?? this.linkedTeachers,
      fileCount: fileCount ?? this.fileCount,
      isLoadingSummaries: isLoadingSummaries ?? this.isLoadingSummaries,
      isLoadingQuizzes: isLoadingQuizzes ?? this.isLoadingQuizzes,
      isLoadingScores: isLoadingScores ?? this.isLoadingScores,
      isLoadingAssignments: isLoadingAssignments ?? this.isLoadingAssignments,
      isLoadingAttendance: isLoadingAttendance ?? this.isLoadingAttendance,
      isLoadingTeachers: isLoadingTeachers ?? this.isLoadingTeachers,
      summariesError: clearSummariesError ? null : (summariesError ?? this.summariesError),
      quizzesError: clearQuizzesError ? null : (quizzesError ?? this.quizzesError),
      scoresError: clearScoresError ? null : (scoresError ?? this.scoresError),
      assignmentsError: clearAssignmentsError ? null : (assignmentsError ?? this.assignmentsError),
      attendanceError: clearAttendanceError ? null : (attendanceError ?? this.attendanceError),
      teachersError: clearTeachersError ? null : (teachersError ?? this.teachersError),
    );
  }
}

// ─── Dashboard Controller ───

class StudentDashboardController extends StateNotifier<DashboardState> {
  final StudentApiService _apiService;

  StudentDashboardController(this._apiService) : super(const DashboardState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    fetchSummaries();
    fetchQuizzes();
    fetchScores();
    fetchAssignments();
    fetchAttendance();
    fetchLinkedTeachers();
  }

  Future<void> refresh() => loadAll();

  // ── Summaries ──

  Future<void> fetchSummaries() async {
    state = state.copyWith(isLoadingSummaries: true, clearSummariesError: true);
    try {
      final summaries = await _apiService.fetchSummaries();
      state = state.copyWith(
        summaries: summaries,
        isLoadingSummaries: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSummaries: false,
        summariesError: _friendlyError(e),
      );
    }
  }

  // ── Quizzes ──

  Future<void> fetchQuizzes() async {
    state = state.copyWith(isLoadingQuizzes: true, clearQuizzesError: true);
    try {
      final quizzes = await _apiService.fetchQuizzes();
      state = state.copyWith(quizzes: quizzes, isLoadingQuizzes: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingQuizzes: false,
        quizzesError: _friendlyError(e),
      );
    }
  }

  // ── Scores ──

  Future<void> fetchScores() async {
    state = state.copyWith(isLoadingScores: true, clearScoresError: true);
    try {
      final scores = await _apiService.fetchScores();
      state = state.copyWith(scores: scores, isLoadingScores: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingScores: false,
        scoresError: _friendlyError(e),
      );
    }
  }

  // ── Assignments ──

  Future<void> fetchAssignments() async {
    state = state.copyWith(isLoadingAssignments: true, clearAssignmentsError: true);
    try {
      final assignments = await _apiService.fetchAssignments();
      state = state.copyWith(
        assignments: assignments,
        isLoadingAssignments: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAssignments: false,
        assignmentsError: _friendlyError(e),
      );
    }
  }

  // ── Attendance ──

  Future<void> fetchAttendance() async {
    state = state.copyWith(isLoadingAttendance: true, clearAttendanceError: true);
    try {
      final attendance = await _apiService.fetchAttendance();
      state = state.copyWith(
        attendance: attendance,
        isLoadingAttendance: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAttendance: false,
        attendanceError: _friendlyError(e),
      );
    }
  }

  // ── Linked Teachers ──

  Future<void> fetchLinkedTeachers() async {
    state = state.copyWith(isLoadingTeachers: true, clearTeachersError: true);
    try {
      final teachers = await _apiService.fetchLinkedTeachers();
      state = state.copyWith(
        linkedTeachers: teachers,
        isLoadingTeachers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTeachers: false,
        teachersError: _friendlyError(e),
      );
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Failed to load data. Please try again.';
  }
}

// ─── Provider ───

final studentDashboardControllerProvider =
    StateNotifierProvider<StudentDashboardController, DashboardState>((ref) {
  return StudentDashboardController(ref.watch(studentApiServiceProvider));
});

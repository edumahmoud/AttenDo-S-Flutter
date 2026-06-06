import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Assignments State ───

class AssignmentsState {
  final List<Assignment> assignments;
  final List<Submission> submissions;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const AssignmentsState({
    this.assignments = const [],
    this.submissions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  /// Assignments not yet submitted (no submission with submittedAt).
  List<Assignment> get pendingAssignments => assignments.where((a) {
        final subs = a.submissions ?? [];
        return subs.isEmpty ||
            subs.every((s) => s.submittedAt == null);
      }).toList();

  /// Assignments that have been submitted.
  List<Assignment> get submittedAssignments => assignments.where((a) {
        final subs = a.submissions ?? [];
        return subs.any((s) => s.submittedAt != null);
      }).toList();

  /// Assignments past due date and not submitted.
  List<Assignment> get overdueAssignments => pendingAssignments
      .where((a) => a.dueDate != null && a.dueDate!.isBefore(DateTime.now()))
      .toList();

  AssignmentsState copyWith({
    List<Assignment>? assignments,
    List<Submission>? submissions,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return AssignmentsState(
      assignments: assignments ?? this.assignments,
      submissions: submissions ?? this.submissions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Assignments Controller ───

class AssignmentsController extends StateNotifier<AssignmentsState> {
  final StudentApiService _apiService;

  AssignmentsController(this._apiService)
      : super(const AssignmentsState()) {
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final assignments = await _apiService.fetchAssignments();
      state = state.copyWith(assignments: assignments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<bool> submitAssignment(
    String assignmentId, {
    String? content,
    String? fileId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final data = <String, dynamic>{
        'assignmentId': assignmentId,
        if (content != null) 'content': content,
        if (fileId != null) 'fileId': fileId,
      };
      await _apiService.submitAssignment(data);
      // Refresh assignments after submission
      await fetchAssignments();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<void> fetchSubmissions() async {
    // Submissions are embedded in assignments from fetchAssignments
    // This method can be used for a dedicated submissions view
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final assignments = await _apiService.fetchAssignments();
      final allSubmissions = <Submission>[];
      for (final a in assignments) {
        if (a.submissions != null) {
          allSubmissions.addAll(a.submissions!);
        }
      }
      state = state.copyWith(
        assignments: assignments,
        submissions: allSubmissions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
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
    return 'Failed to load assignments. Please try again.';
  }
}

// ─── Provider ───

final assignmentsControllerProvider =
    StateNotifierProvider<AssignmentsController, AssignmentsState>((ref) {
  return AssignmentsController(ref.watch(studentApiServiceProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Subjects State ───

class SubjectsState {
  final List<Subject> subjects;
  final Subject? selectedSubject;
  final bool isLoading;
  final String? error;

  const SubjectsState({
    this.subjects = const [],
    this.selectedSubject,
    this.isLoading = false,
    this.error,
  });

  SubjectsState copyWith({
    List<Subject>? subjects,
    Subject? selectedSubject,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedSubject = false,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      selectedSubject:
          clearSelectedSubject ? null : (selectedSubject ?? this.selectedSubject),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Subjects Controller ───

class SubjectsController extends StateNotifier<SubjectsState> {
  final StudentApiService _apiService;
  final SupabaseService _supabaseService;

  SubjectsController(this._apiService, this._supabaseService)
      : super(const SubjectsState()) {
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('student_subjects')
          .select('subject:subjects(*)')
          .eq('student_id', userId);

      final subjects = (data as List<dynamic>)
          .map((row) {
            final subjectJson = row['subject'];
            if (subjectJson == null) return null;
            return Subject.fromJson(subjectJson as Map<String, dynamic>);
          })
          .whereType<Subject>()
          .toList();

      state = state.copyWith(subjects: subjects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<bool> joinSubject(String code) async {
    state = state.copyWith(clearError: true);
    try {
      final subject = await _apiService.joinSubject(code);
      state = state.copyWith(subjects: [...state.subjects, subject]);
      return true;
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> leaveSubject(String subjectId) async {
    final previousSubjects = state.subjects;
    state = state.copyWith(
      subjects: state.subjects.where((s) => s.id != subjectId).toList(),
    );
    try {
      await _apiService.leaveSubject(subjectId);
      return true;
    } catch (e) {
      state = state.copyWith(subjects: previousSubjects, error: _friendlyError(e));
      return false;
    }
  }

  void selectSubject(String subjectId) {
    final matched = state.subjects.where((s) => s.id == subjectId);
    if (matched.isEmpty) return;
    final subject = matched.first;
    state = state.copyWith(selectedSubject: subject);
  }

  void clearSelectedSubject() {
    state = state.copyWith(clearSelectedSubject: true);
  }

  Future<void> fetchSubjectDetails(String subjectId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _supabaseService.client
          .from('subjects')
          .select()
          .eq('id', subjectId)
          .single();

      final subject = Subject.fromJson(data);
      state = state.copyWith(
        subjects: state.subjects
            .map((s) => s.id == subjectId ? subject : s)
            .toList(),
        selectedSubject: subject,
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
    if (msg.contains('not found') || msg.contains('Invalid code')) {
      return 'Subject not found. Please check the code and try again.';
    }
    return 'Failed to load subjects. Please try again.';
  }
}

// ─── Provider ───

final subjectsControllerProvider =
    StateNotifierProvider<SubjectsController, SubjectsState>((ref) {
  return SubjectsController(
    ref.watch(studentApiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

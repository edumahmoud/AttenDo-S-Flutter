import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Teachers State ───

class TeachersState {
  final List<UserProfile> linkedTeachers;
  final List<TeacherStudentLink> incomingRequests;
  final bool isLoadingTeachers;
  final bool isLoadingRequests;
  final bool isSendingRequest;
  final String? teachersError;
  final String? requestsError;
  final String? actionError;

  const TeachersState({
    this.linkedTeachers = const [],
    this.incomingRequests = const [],
    this.isLoadingTeachers = false,
    this.isLoadingRequests = false,
    this.isSendingRequest = false,
    this.teachersError,
    this.requestsError,
    this.actionError,
  });

  TeachersState copyWith({
    List<UserProfile>? linkedTeachers,
    List<TeacherStudentLink>? incomingRequests,
    bool? isLoadingTeachers,
    bool? isLoadingRequests,
    bool? isSendingRequest,
    String? teachersError,
    String? requestsError,
    String? actionError,
    bool clearTeachersError = false,
    bool clearRequestsError = false,
    bool clearActionError = false,
  }) {
    return TeachersState(
      linkedTeachers: linkedTeachers ?? this.linkedTeachers,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      isLoadingTeachers: isLoadingTeachers ?? this.isLoadingTeachers,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isSendingRequest: isSendingRequest ?? this.isSendingRequest,
      teachersError:
          clearTeachersError ? null : (teachersError ?? this.teachersError),
      requestsError:
          clearRequestsError ? null : (requestsError ?? this.requestsError),
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

// ─── Teachers Controller ───

class TeachersController extends StateNotifier<TeachersState> {
  final StudentApiService _apiService;
  final SupabaseService _supabaseService;

  TeachersController(this._apiService, this._supabaseService)
      : super(const TeachersState()) {
    fetchLinkedTeachers();
    fetchIncomingLinkRequests();
  }

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

  Future<void> fetchIncomingLinkRequests() async {
    state = state.copyWith(isLoadingRequests: true, clearRequestsError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('teacher_student_links')
          .select()
          .eq('student_id', userId)
          .eq('status', 'pending');

      final requests = (data as List<dynamic>)
          .map((json) =>
              TeacherStudentLink.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        incomingRequests: requests,
        isLoadingRequests: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingRequests: false,
        requestsError: _friendlyError(e),
      );
    }
  }

  Future<bool> sendLinkRequest(String teacherCode) async {
    state = state.copyWith(isSendingRequest: true, clearActionError: true);
    try {
      await _apiService.sendTeacherLink(teacherCode);
      state = state.copyWith(isSendingRequest: false);
      await fetchIncomingLinkRequests();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSendingRequest: false,
        actionError: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> approveLinkRequest(String requestId) async {
    state = state.copyWith(clearActionError: true);
    try {
      await _apiService.approveTeacherLink(requestId);
      // Remove from pending and refresh
      state = state.copyWith(
        incomingRequests:
            state.incomingRequests.where((r) => r.id != requestId).toList(),
      );
      await fetchLinkedTeachers();
      return true;
    } catch (e) {
      state = state.copyWith(actionError: _friendlyError(e));
      return false;
    }
  }

  Future<bool> cancelLinkRequest(String requestId) async {
    state = state.copyWith(clearActionError: true);
    try {
      await _apiService.cancelTeacherLink(requestId);
      state = state.copyWith(
        incomingRequests:
            state.incomingRequests.where((r) => r.id != requestId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(actionError: _friendlyError(e));
      return false;
    }
  }

  Future<bool> unlinkTeacher(String teacherId) async {
    state = state.copyWith(clearActionError: true);
    final previousTeachers = state.linkedTeachers;
    state = state.copyWith(
      linkedTeachers:
          state.linkedTeachers.where((t) => t.id != teacherId).toList(),
    );
    try {
      await _apiService.unlinkTeacher(teacherId);
      return true;
    } catch (e) {
      state = state.copyWith(
        linkedTeachers: previousTeachers,
        actionError: _friendlyError(e),
      );
      return false;
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('not found') || msg.contains('Invalid')) {
      return 'Teacher not found. Please check the code and try again.';
    }
    if (msg.contains('already')) {
      return 'A link request already exists for this teacher.';
    }
    return 'An error occurred. Please try again.';
  }
}

// ─── Provider ───

final teachersControllerProvider =
    StateNotifierProvider<TeachersController, TeachersState>((ref) {
  return TeachersController(
    ref.watch(studentApiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

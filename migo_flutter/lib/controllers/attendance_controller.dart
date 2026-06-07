import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Attendance State ───

class AttendanceState {
  final List<AttendanceRecord> records;
  final List<AttendanceSession> sessions;
  final bool isLoading;
  final bool isCheckingIn;
  final String? error;

  const AttendanceState({
    this.records = const [],
    this.sessions = const [],
    this.isLoading = false,
    this.isCheckingIn = false,
    this.error,
  });

  /// Overall attendance rate (present + late / total).
  double get attendanceRate {
    if (records.isEmpty) return 0;
    final present = records
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length;
    return (present / records.length) * 100;
  }

  int get presentCount =>
      records.where((r) => r.status == AttendanceStatus.present).length;

  int get absentCount =>
      records.where((r) => r.status == AttendanceStatus.absent).length;

  int get lateCount =>
      records.where((r) => r.status == AttendanceStatus.late).length;

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    List<AttendanceSession>? sessions,
    bool? isLoading,
    bool? isCheckingIn,
    String? error,
    bool clearError = false,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Attendance Controller ───

class AttendanceController extends StateNotifier<AttendanceState> {
  final StudentApiService _apiService;
  final SupabaseService _supabaseService;

  AttendanceController(this._apiService, this._supabaseService)
      : super(const AttendanceState()) {
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('attendance_records')
          .select()
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      final records = (data as List<dynamic>)
          .map((json) =>
              AttendanceRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> fetchAttendanceSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = await _apiService.fetchAttendance();
      final allRecords = <AttendanceRecord>[];
      for (final session in sessions) {
        if (session.records != null) {
          allRecords.addAll(session.records!);
        }
      }
      state = state.copyWith(
        sessions: sessions,
        records: allRecords,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<bool> scanQRCode(String qrData) async {
    state = state.copyWith(isCheckingIn: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // QR data contains the session ID
      await _supabaseService.client.from('attendance_records').insert({
        'session_id': qrData,
        'student_id': userId,
        'status': AppConstants.attendancePresent,
      });

      await fetchAttendanceRecords();
      state = state.copyWith(isCheckingIn: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCheckingIn: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> manualCheckIn(String sessionId) async {
    state = state.copyWith(isCheckingIn: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabaseService.client.from('attendance_records').insert({
        'session_id': sessionId,
        'student_id': userId,
        'status': AppConstants.attendancePresent,
      });

      await fetchAttendanceRecords();
      state = state.copyWith(isCheckingIn: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isCheckingIn: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('already') || msg.contains('duplicate')) {
      return 'You have already checked in for this session.';
    }
    if (msg.contains('expired')) {
      return 'This attendance session has expired.';
    }
    return 'Failed to check in. Please try again.';
  }
}

// ─── Provider ───

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
  return AttendanceController(
    ref.watch(studentApiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

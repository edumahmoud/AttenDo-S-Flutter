import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Reports State ───

class ReportsState {
  final List<Report> reports;
  final List<ReportMessage> activeReportMessages;
  final String? activeReportId;
  final bool isLoadingReports;
  final bool isLoadingMessages;
  final bool isCreating;
  final bool isSendingMessage;
  final String? reportsError;
  final String? messagesError;
  final String? actionError;

  const ReportsState({
    this.reports = const [],
    this.activeReportMessages = const [],
    this.activeReportId,
    this.isLoadingReports = false,
    this.isLoadingMessages = false,
    this.isCreating = false,
    this.isSendingMessage = false,
    this.reportsError,
    this.messagesError,
    this.actionError,
  });

  ReportsState copyWith({
    List<Report>? reports,
    List<ReportMessage>? activeReportMessages,
    String? activeReportId,
    bool? isLoadingReports,
    bool? isLoadingMessages,
    bool? isCreating,
    bool? isSendingMessage,
    String? reportsError,
    String? messagesError,
    String? actionError,
    bool clearReportsError = false,
    bool clearMessagesError = false,
    bool clearActionError = false,
    bool clearActiveReport = false,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      activeReportMessages:
          activeReportMessages ?? this.activeReportMessages,
      activeReportId:
          clearActiveReport ? null : (activeReportId ?? this.activeReportId),
      isLoadingReports: isLoadingReports ?? this.isLoadingReports,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isCreating: isCreating ?? this.isCreating,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      reportsError:
          clearReportsError ? null : (reportsError ?? this.reportsError),
      messagesError:
          clearMessagesError ? null : (messagesError ?? this.messagesError),
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

// ─── Reports Controller ───

class ReportsController extends StateNotifier<ReportsState> {
  final StudentApiService _apiService;
  final SupabaseService _supabaseService;

  ReportsController(this._apiService, this._supabaseService)
      : super(const ReportsState()) {
    fetchReports();
  }

  Future<void> fetchReports() async {
    state = state.copyWith(isLoadingReports: true, clearReportsError: true);
    try {
      final reports = await _apiService.fetchReports();
      state = state.copyWith(reports: reports, isLoadingReports: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingReports: false,
        reportsError: _friendlyError(e),
      );
    }
  }

  Future<bool> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    state = state.copyWith(isCreating: true, clearActionError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final report = await _apiService.createReport({
        'userId': userId,
        'title': reason,
        'description': description ?? '',
        'type': 'complaint',
        'priority': 'medium',
        'referenceType': targetType,
        'referenceId': targetId,
      });

      state = state.copyWith(
        reports: [report, ...state.reports],
        isCreating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isCreating: false, actionError: _friendlyError(e));
      return false;
    }
  }

  Future<void> fetchReportMessages(String reportId) async {
    state = state.copyWith(
      isLoadingMessages: true,
      clearMessagesError: true,
      activeReportId: reportId,
    );
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('report_messages')
          .select()
          .eq('report_id', reportId)
          .order('created_at', ascending: true);

      final messages = (data as List<dynamic>)
          .map((json) =>
              ReportMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        activeReportMessages: messages,
        isLoadingMessages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        messagesError: _friendlyError(e),
      );
    }
  }

  Future<bool> sendReportMessage(String reportId, String content) async {
    state = state.copyWith(isSendingMessage: true, clearActionError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final result = await _supabaseService.client
          .from('report_messages')
          .insert({
            'report_id': reportId,
            'sender_id': userId,
            'content': content.trim(),
          })
          .select()
          .single();

      final message = ReportMessage.fromJson(result);
      state = state.copyWith(
        activeReportMessages: [...state.activeReportMessages, message],
        isSendingMessage: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSendingMessage: false,
        actionError: _friendlyError(e),
      );
      return false;
    }
  }

  void clearActiveReport() {
    state = state.copyWith(
      clearActiveReport: true,
      activeReportMessages: [],
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred. Please try again.';
  }
}

// ─── Provider ───

final reportsControllerProvider =
    StateNotifierProvider<ReportsController, ReportsState>((ref) {
  return ReportsController(
    ref.watch(studentApiServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

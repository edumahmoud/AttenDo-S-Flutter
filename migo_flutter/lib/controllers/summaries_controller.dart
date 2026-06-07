import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Summaries State ───

class SummariesState {
  final List<Summary> summaries;
  final bool isLoading;
  final String? error;
  final Set<String> pendingSummaryIds;
  final bool isGenerating;

  const SummariesState({
    this.summaries = const [],
    this.isLoading = false,
    this.error,
    this.pendingSummaryIds = const {},
    this.isGenerating = false,
  });

  SummariesState copyWith({
    List<Summary>? summaries,
    bool? isLoading,
    String? error,
    Set<String>? pendingSummaryIds,
    bool? isGenerating,
    bool clearError = false,
  }) {
    return SummariesState(
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingSummaryIds: pendingSummaryIds ?? this.pendingSummaryIds,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

// ─── Summaries Controller ───

class SummariesController extends StateNotifier<SummariesState> {
  final StudentApiService _apiService;
  final AiService _aiService;

  SummariesController(this._apiService, this._aiService)
      : super(const SummariesState()) {
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summaries = await _apiService.fetchSummaries();
      state = state.copyWith(summaries: summaries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> createSummary({
    required String content,
    required String sourceType,
    String? subjectId,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      // Step 1: Generate AI summary
      final aiResult = await _aiService.generateSummary(
        content: content,
        sourceType: sourceType,
      );

      // Step 2: Persist the summary
      final summaryData = <String, dynamic>{
        'originalContent': content,
        'summaryContent': aiResult['summary'] ?? '',
        'title': aiResult['title'] ?? 'Untitled Summary',
        'sourceFileType': sourceType,
        if (subjectId != null) 'subjectId': subjectId,
      };
      final summary = await _apiService.createSummary(summaryData);

      state = state.copyWith(
        summaries: [summary, ...state.summaries],
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> deleteSummary(String id) async {
    final previousSummaries = state.summaries;
    state = state.copyWith(
      summaries: state.summaries.where((s) => s.id != id).toList(),
    );
    try {
      await _apiService.deleteSummary(id);
    } catch (e) {
      state = state.copyWith(
        summaries: previousSummaries,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> renameSummary(String id, String newTitle) async {
    final previousSummaries = state.summaries;
    state = state.copyWith(
      summaries: state.summaries
          .map((s) => s.id == id ? s.copyWith(title: newTitle) : s)
          .toList(),
    );
    try {
      await _apiService.createSummary({
        'id': id,
        'title': newTitle,
      });
    } catch (e) {
      state = state.copyWith(
        summaries: previousSummaries,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> generateQuizFromSummary(
    String summaryId, {
    Map<String, dynamic>? config,
  }) async {
    final pending = {...state.pendingSummaryIds}..add(summaryId);
    state = state.copyWith(pendingSummaryIds: pending);
    try {
      await _aiService.generateQuiz(summaryId: summaryId, config: config);
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    } finally {
      final updated = {...state.pendingSummaryIds}..remove(summaryId);
      state = state.copyWith(pendingSummaryIds: updated);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('timeout')) {
      return 'Summary generation timed out. Please try again.';
    }
    return 'Failed to process summary. Please try again.';
  }
}

// ─── Provider ───

final summariesControllerProvider =
    StateNotifierProvider<SummariesController, SummariesState>((ref) {
  return SummariesController(
    ref.watch(studentApiServiceProvider),
    ref.watch(aiServiceProvider),
  );
});

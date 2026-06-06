import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Quiz State ───

enum QuizPhase { idle, active, submitted, reviewing }

class QuizState {
  final QuizPhase phase;
  final Quiz? quiz;
  final Score? score;
  final int currentQuestionIndex;
  final Map<int, String> answers; // questionIndex -> answer
  final Map<int, List<MatchingPair>> matchingAnswers;
  final int? timeRemainingSeconds;
  final bool isLoading;
  final String? error;

  const QuizState({
    this.phase = QuizPhase.idle,
    this.quiz,
    this.score,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.matchingAnswers = const {},
    this.timeRemainingSeconds,
    this.isLoading = false,
    this.error,
  });

  int get totalQuestions => quiz?.questions?.length ?? 0;

  bool get isLastQuestion => currentQuestionIndex >= totalQuestions - 1;

  QuizQuestion? get currentQuestion {
    if (quiz?.questions == null || currentQuestionIndex >= totalQuestions) {
      return null;
    }
    return quiz!.questions![currentQuestionIndex];
  }

  double get progress =>
      totalQuestions > 0 ? (currentQuestionIndex + 1) / totalQuestions : 0;

  QuizState copyWith({
    QuizPhase? phase,
    Quiz? quiz,
    Score? score,
    int? currentQuestionIndex,
    Map<int, String>? answers,
    Map<int, List<MatchingPair>>? matchingAnswers,
    int? timeRemainingSeconds,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearTimeRemaining = false,
  }) {
    return QuizState(
      phase: phase ?? this.phase,
      quiz: quiz ?? this.quiz,
      score: score ?? this.score,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      matchingAnswers: matchingAnswers ?? this.matchingAnswers,
      timeRemainingSeconds:
          clearTimeRemaining ? null : (timeRemainingSeconds ?? this.timeRemainingSeconds),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Quiz Controller ───

class QuizController extends StateNotifier<QuizState> {
  final StudentApiService _apiService;
  Timer? _timer;

  QuizController(this._apiService) : super(const QuizState());

  Future<void> startQuiz(String quizId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quizzes = await _apiService.fetchQuizzes();
      final quiz = quizzes.firstWhere(
        (q) => q.id == quizId,
        orElse: () => throw Exception('Quiz not found'),
      );

      final duration = quiz.timeLimitMinutes ??
          AppConstants.quizDefaultDurationMinutes;
      final remainingSeconds = duration * 60;

      state = QuizState(
        phase: QuizPhase.active,
        quiz: quiz,
        timeRemainingSeconds: remainingSeconds,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeRemainingSeconds == null || state.phase != QuizPhase.active) {
        _timer?.cancel();
        return;
      }
      final remaining = state.timeRemainingSeconds! - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        submitQuiz();
        return;
      }
      state = state.copyWith(timeRemainingSeconds: remaining);
    });
  }

  void answerQuestion(int questionIndex, String answer) {
    final updated = {...state.answers}..[questionIndex] = answer;
    state = state.copyWith(answers: updated);
  }

  void answerMatchingQuestion(
    int questionIndex,
    List<MatchingPair> pairs,
  ) {
    final updated = {...state.matchingAnswers}..[questionIndex] = pairs;
    state = state.copyWith(matchingAnswers: updated);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state =
          state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state =
          state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, phase: QuizPhase.submitted);
    try {
      // Submit answers via the API
      // The backend handles scoring
      final scores = await _apiService.fetchScores();
      Score? relevantScore;
      for (final s in scores.reversed) {
        if (s.quizId == state.quiz?.id) {
          relevantScore = s;
          break;
        }
      }

      state = state.copyWith(
        isLoading: false,
        phase: QuizPhase.reviewing,
        score: relevantScore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> reviewQuiz(String scoreId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final scores = await _apiService.fetchScores();
      final score = scores.firstWhere(
        (s) => s.id == scoreId,
        orElse: () => throw Exception('Score not found'),
      );
      state = state.copyWith(
        isLoading: false,
        phase: QuizPhase.reviewing,
        score: score,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  void resetQuiz() {
    _timer?.cancel();
    state = const QuizState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('timeout')) {
      return 'Quiz submission timed out. Please try again.';
    }
    return 'An error occurred with the quiz. Please try again.';
  }
}

// ─── Provider ───

final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  return QuizController(ref.watch(studentApiServiceProvider));
});

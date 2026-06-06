import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../i18n/app_localizations.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';

// ────────────────────────────────────────────────────────────────
// Quiz View Screen (Full-screen quiz taking view)
// ────────────────────────────────────────────────────────────────

class QuizViewScreen extends ConsumerStatefulWidget {
  final String quizId;
  final VoidCallback? onBackToSummaries;

  const QuizViewScreen({
    super.key,
    required this.quizId,
    this.onBackToSummaries,
  });

  @override
  ConsumerState<QuizViewScreen> createState() => _QuizViewScreenState();
}

class _QuizViewScreenState extends ConsumerState<QuizViewScreen>
    with WidgetsBindingObserver {
  bool _showBlurOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start the quiz
    Future.microtask(() {
      ref.read(quizControllerProvider.notifier).startQuiz(widget.quizId);
    });
    // Enter full-screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Anti-cheat: show blur overlay when app goes to background
      setState(() => _showBlurOverlay = true);
    } else if (state == AppLifecycleState.resumed) {
      // Show warning
      final quizState = ref.read(quizControllerProvider);
      if (quizState.phase == QuizPhase.active) {
        _showLeaveWarning();
      }
    }
  }

  void _showLeaveWarning() {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.t('quiz.leaveAppWarning')),
        backgroundColor: AppColors.lightAmberAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quizState = ref.watch(quizControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: _buildBody(loc, theme, quizState),
          ),

          // Anti-cheat blur overlay
          if (_showBlurOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: AppColors.lightAmberAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.t('quiz.leaveAppWarning'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _showBlurOverlay = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightOcean,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(loc.t('common.backToApp')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
      AppLocalizations loc, ThemeData theme, QuizState quizState) {
    // ─── Loading ───
    if (quizState.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              loc.t('common.loading'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // ─── Error ───
    if (quizState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                quizState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref
                    .read(quizControllerProvider.notifier)
                    .startQuiz(widget.quizId),
                child: Text(loc.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Reviewing Phase (Results) ───
    if (quizState.phase == QuizPhase.reviewing) {
      return _QuizResultsView(
        quizState: quizState,
        onBackToSummaries: widget.onBackToSummaries ??
            () => Navigator.of(context).pop(),
      );
    }

    // ─── Active Quiz ───
    if (quizState.phase == QuizPhase.active ||
        quizState.phase == QuizPhase.submitted) {
      return _ActiveQuizView(
        quizState: quizState,
        formatTime: _formatTime,
        onExit: () => _confirmExit(loc),
        onSubmit: () => _confirmSubmit(loc, quizState),
      );
    }

    // ─── Idle ───
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(loc.t('common.noData'),
              style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  // ─── Exit Confirmation ───

  void _confirmExit(AppLocalizations loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('quiz.exitConfirmTitle')),
        content: Text(loc.t('quiz.exitConfirmDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(quizControllerProvider.notifier).resetQuiz();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(loc.t('quiz.backButton')),
          ),
        ],
      ),
    );
  }

  // ─── Submit Confirmation ───

  void _confirmSubmit(AppLocalizations loc, QuizState quizState) {
    final totalQuestions = quizState.totalQuestions;
    final answeredCount = quizState.answers.length +
        quizState.matchingAnswers.length;
    final unansweredCount = totalQuestions - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('quiz.submitConfirmTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('quiz.submitConfirmDesc')),
            const SizedBox(height: 16),
            _submitSummaryRow(
              loc.t('quiz.answeredCount', args: {
                'count': answeredCount.toString()
              }),
              AppColors.lightTealAccent,
            ),
            const SizedBox(height: 6),
            _submitSummaryRow(
              loc.t('quiz.unansweredCount', args: {
                'count': unansweredCount.toString()
              }),
              unansweredCount > 0
                  ? AppColors.lightAmberAccent
                  : Colors.grey,
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightAmberAccent.withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusGeometry,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.lightAmberAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.t('quiz.warningUnanswered'),
                        style: TextStyle(
                          color: AppColors.lightAmberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(quizControllerProvider.notifier).submitQuiz();
            },
            child: Text(loc.t('quiz.finishQuiz')),
          ),
        ],
      ),
    );
  }

  Widget _submitSummaryRow(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Active Quiz View (question display + navigation)
// ────────────────────────────────────────────────────────────────

class _ActiveQuizView extends ConsumerWidget {
  final QuizState quizState;
  final String Function(int) formatTime;
  final VoidCallback onExit;
  final VoidCallback onSubmit;

  const _ActiveQuizView({
    required this.quizState,
    required this.formatTime,
    required this.onExit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quiz = quizState.quiz;
    final questions = quiz?.questions ?? [];
    final currentIndex = quizState.currentQuestionIndex;
    final currentQuestion =
        currentIndex < questions.length ? questions[currentIndex] : null;

    if (currentQuestion == null) {
      return const Center(child: Text('No question available'));
    }

    final isSubmitting = quizState.phase == QuizPhase.submitted;
    final timeRemaining = quizState.timeRemainingSeconds ?? 0;
    final isUrgent = timeRemaining < 300; // < 5 minutes

    return Column(
      children: [
        // ─── Quiz Header ───
        _buildQuizHeader(loc, theme, timeRemaining, isUrgent, currentIndex,
            questions.length, isSubmitting),

        // ─── Progress bar ───
        LinearProgressIndicator(
          value: quizState.progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: theme.colorScheme.primary,
          minHeight: 3,
        ),

        // ─── Question Content ───
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge + type
                _buildQuestionHeader(
                    loc, theme, currentQuestion, currentIndex),
                const SizedBox(height: 20),

                // Question text
                Text(
                  currentQuestion.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Question type-specific input
                _buildQuestionInput(
                    context, ref, loc, theme, currentQuestion, currentIndex),
              ],
            ),
          ),
        ),

        // ─── Bottom Navigation ───
        _buildBottomNavigation(
            loc, theme, ref, currentIndex, questions.length),
      ],
    );
  }

  // ─── Quiz Header ───

  Widget _buildQuizHeader(
    AppLocalizations loc,
    ThemeData theme,
    int timeRemaining,
    bool isUrgent,
    int currentIndex,
    int totalQuestions,
    bool isSubmitting,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Exit button
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: isSubmitting ? null : onExit,
              iconSize: 22,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                quizState.quiz?.title ?? '',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppColors.lightDestructive.withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUrgent
                        ? Icons.timer_off_rounded
                        : Icons.timer_rounded,
                    size: 16,
                    color: isUrgent
                        ? AppColors.lightDestructive
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatTime(timeRemaining),
                    style: TextStyle(
                      color: isUrgent
                          ? AppColors.lightDestructive
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Question progress
            Text(
              '${currentIndex + 1}/$totalQuestions',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Question Header ───

  Widget _buildQuestionHeader(
    AppLocalizations loc,
    ThemeData theme,
    QuizQuestion question,
    int index,
  ) {
    final typeLabel = switch (question.type) {
      QuizQuestionType.mcq => loc.t('quiz.typeMcq'),
      QuizQuestionType.boolean_ => loc.t('quiz.typeBoolean'),
      QuizQuestionType.completion => loc.t('quiz.typeCompletion'),
      QuizQuestionType.matching => loc.t('quiz.typeMatching'),
    };

    return Row(
      children: [
        // Question number badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.lightOcean,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            typeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Question Input ───

  Widget _buildQuestionInput(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    QuizQuestion question,
    int questionIndex,
  ) {
    final selectedAnswer = quizState.answers[questionIndex];

    switch (question.type) {
      case QuizQuestionType.mcq:
        return _buildMcqOptions(
            ref, loc, theme, question, questionIndex, selectedAnswer);

      case QuizQuestionType.boolean_:
        return _buildBooleanOptions(
            ref, loc, theme, questionIndex, selectedAnswer);

      case QuizQuestionType.completion:
        return _buildCompletionInput(
            ref, loc, theme, questionIndex, selectedAnswer);

      case QuizQuestionType.matching:
        return _buildMatchingInput(
            ref, loc, theme, question, questionIndex);
    }
  }

  // ─── MCQ Options ───

  Widget _buildMcqOptions(
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    QuizQuestion question,
    int questionIndex,
    String? selectedAnswer,
  ) {
    final options = question.options ?? [];
    final optionLetters = [
      loc.t('quiz.optionA'),
      loc.t('quiz.optionB'),
      loc.t('quiz.optionC'),
      loc.t('quiz.optionD'),
    ];

    return Column(
      children: List.generate(options.length, (i) {
        final option = options[i];
        final letter = i < optionLetters.length ? optionLetters[i] : '${i + 1}';
        final isSelected = selectedAnswer == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => ref
                .read(quizControllerProvider.notifier)
                .answerQuestion(questionIndex, option),
            borderRadius: AppTheme.borderRadiusGeometry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lightOcean.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppTheme.borderRadiusGeometry,
                border: Border.all(
                  color: isSelected
                      ? AppColors.lightOcean
                      : theme.colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Letter circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.lightOcean
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.lightOcean
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : Text(
                              letter,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.lightOcean
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Boolean Options ───

  Widget _buildBooleanOptions(
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    int questionIndex,
    String? selectedAnswer,
  ) {
    final trueSelected = selectedAnswer == 'true';
    final falseSelected = selectedAnswer == 'false';

    return Row(
      children: [
        // True button
        Expanded(
          child: InkWell(
            onTap: () => ref
                .read(quizControllerProvider.notifier)
                .answerQuestion(questionIndex, 'true'),
            borderRadius: AppTheme.borderRadiusGeometry,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: trueSelected
                    ? AppColors.lightTealAccent.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppTheme.borderRadiusGeometry,
                border: Border.all(
                  color: trueSelected
                      ? AppColors.lightTealAccent
                      : theme.colorScheme.outline,
                  width: trueSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 40,
                    color: trueSelected
                        ? AppColors.lightTealAccent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('quiz.booleanTrue'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: trueSelected
                          ? AppColors.lightTealAccent
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          trueSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // False button
        Expanded(
          child: InkWell(
            onTap: () => ref
                .read(quizControllerProvider.notifier)
                .answerQuestion(questionIndex, 'false'),
            borderRadius: AppTheme.borderRadiusGeometry,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: falseSelected
                    ? AppColors.lightDestructive.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppTheme.borderRadiusGeometry,
                border: Border.all(
                  color: falseSelected
                      ? AppColors.lightDestructive
                      : theme.colorScheme.outline,
                  width: falseSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 40,
                    color: falseSelected
                        ? AppColors.lightDestructive
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('quiz.booleanFalse'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: falseSelected
                          ? AppColors.lightDestructive
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          falseSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Completion Input ───

  Widget _buildCompletionInput(
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    int questionIndex,
    String? currentAnswer,
  ) {
    return TextField(
      onChanged: (value) => ref
          .read(quizControllerProvider.notifier)
          .answerQuestion(questionIndex, value),
      decoration: InputDecoration(
        hintText: loc.t('quiz.completionPlaceholder'),
        prefixIcon: const Icon(Icons.edit_rounded),
        suffixIcon: currentAnswer != null && currentAnswer.isNotEmpty
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.lightTealAccent)
            : null,
      ),
      style: theme.textTheme.bodyLarge,
      maxLines: 3,
      minLines: 1,
    );
  }

  // ─── Matching Input ───

  Widget _buildMatchingInput(
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    QuizQuestion question,
    int questionIndex,
  ) {
    final pairs = question.pairs ?? [];
    final matchingAnswers = quizState.matchingAnswers[questionIndex] ?? [];
    return _MatchingWidget(
      pairs: pairs,
      matchingAnswers: matchingAnswers,
      onMatchUpdate: (updatedPairs) => ref
          .read(quizControllerProvider.notifier)
          .answerMatchingQuestion(questionIndex, updatedPairs),
    );
  }

  // ─── Bottom Navigation ───

  Widget _buildBottomNavigation(
    AppLocalizations loc,
    ThemeData theme,
    WidgetRef ref,
    int currentIndex,
    int totalQuestions,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question map (grid of numbered circles)
            _buildQuestionMap(loc, theme, ref, currentIndex, totalQuestions),

            const SizedBox(height: 12),

            // Previous / Next / Submit buttons
            Row(
              children: [
                // Previous
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentIndex > 0
                        ? () => ref
                            .read(quizControllerProvider.notifier)
                            .previousQuestion()
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(loc.t('quiz.previous')),
                  ),
                ),
                const SizedBox(width: 12),

                // Next or Submit
                if (quizState.isLastQuestion)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSubmit,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(loc.t('quiz.finishQuiz')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightOcean,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(quizControllerProvider.notifier)
                          .nextQuestion(),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(loc.t('quiz.next')),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Question Map ───

  Widget _buildQuestionMap(
    AppLocalizations loc,
    ThemeData theme,
    WidgetRef ref,
    int currentIndex,
    int totalQuestions,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(totalQuestions, (index) {
        final isAnswered = quizState.answers.containsKey(index) ||
            quizState.matchingAnswers.containsKey(index);
        final isCurrent = index == currentIndex;

        Color bgColor;
        Color fgColor;
        if (isCurrent) {
          bgColor = AppColors.lightOcean;
          fgColor = Colors.white;
        } else if (isAnswered) {
          bgColor = AppColors.lightOcean.withValues(alpha: 0.15);
          fgColor = AppColors.lightOcean;
        } else {
          bgColor = theme.colorScheme.surfaceContainerHighest;
          fgColor = theme.colorScheme.onSurfaceVariant;
        }

        return InkWell(
          onTap: () {
            // Jump to specific question by setting currentQuestionIndex
            // We navigate one by one since the controller doesn't have a jump method
            // A real implementation would add a goToQuestion method
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isCurrent
                  ? Border.all(color: AppColors.lightOcean, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: fgColor,
                  fontWeight:
                      isCurrent || isAnswered ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Matching Widget
// ────────────────────────────────────────────────────────────────

class _MatchingWidget extends StatefulWidget {
  final List<MatchingPair> pairs;
  final List<MatchingPair> matchingAnswers;
  final ValueChanged<List<MatchingPair>> onMatchUpdate;

  const _MatchingWidget({
    required this.pairs,
    required this.matchingAnswers,
    required this.onMatchUpdate,
  });

  @override
  State<_MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<_MatchingWidget> {
  String? _selectedKey;
  final Map<String, String> _matches = {};

  @override
  void initState() {
    super.initState();
    // Initialize from existing answers
    for (final pair in widget.matchingAnswers) {
      _matches[pair.key] = pair.value;
    }
  }

  Color _pairColor(String key) {
    final colors = [
      AppColors.lightOcean,
      AppColors.lightTealAccent,
      AppColors.lightAmberAccent,
      AppColors.lightDestructive,
      const Color(0xFF8B5CF6), // violet
      const Color(0xFFEC4899), // pink
    ];
    final index = widget.pairs.indexWhere((p) => p.key == key);
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shuffledValues = widget.pairs.map((p) => p.value).toList()
      ..shuffle(); // Shuffle for challenge

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).t('quiz.matchingInstructions'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Two columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column A (Keys)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context).t('quiz.listA'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  ...widget.pairs.map((pair) {
                    final isSelected = _selectedKey == pair.key;
                    final isMatched = _matches.containsKey(pair.key);
                    final color = _pairColor(pair.key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedKey == pair.key) {
                              _selectedKey = null;
                            } else {
                              _selectedKey = pair.key;
                            }
                          });
                        },
                        borderRadius: AppTheme.borderRadiusGeometry,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : isMatched
                                    ? color.withValues(alpha: 0.08)
                                    : theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                            borderRadius: AppTheme.borderRadiusGeometry,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : isMatched
                                      ? color.withValues(alpha: 0.4)
                                      : theme.colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isMatched)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsetsDirectional.only(end: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  pair.key,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Column B (Values)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppLocalizations.of(context).t('quiz.listB'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  ...shuffledValues.map((value) {
                    final isMatchedTo =
                        _matches.containsValue(value);
                    final matchedKey = _matches.entries
                        .where((e) => e.value == value)
                        .firstOrNull
                        ?.key;
                    final color = matchedKey != null
                        ? _pairColor(matchedKey)
                        : Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _selectedKey != null && !isMatchedTo
                            ? () {
                                setState(() {
                                  // Remove any existing match for this key
                                  _matches[_selectedKey!] = value;
                                  _selectedKey = null;
                                });
                                _notifyMatches();
                              }
                            : isMatchedTo
                                ? () {
                                    // Un-match
                                    setState(() {
                                      _matches.removeWhere(
                                          (_, v) => v == value);
                                    });
                                    _notifyMatches();
                                  }
                                : null,
                        borderRadius: AppTheme.borderRadiusGeometry,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMatchedTo
                                ? color.withValues(alpha: 0.08)
                                : theme
                                    .colorScheme.surfaceContainerHighest,
                            borderRadius: AppTheme.borderRadiusGeometry,
                            border: Border.all(
                              color: isMatchedTo
                                  ? color.withValues(alpha: 0.4)
                                  : theme.colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isMatchedTo)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsetsDirectional.only(
                                      end: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isMatchedTo
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _notifyMatches() {
    final pairs = _matches.entries
        .map((e) => MatchingPair(key: e.key, value: e.value))
        .toList();
    widget.onMatchUpdate(pairs);
  }
}

// ────────────────────────────────────────────────────────────────
// Quiz Results View
// ────────────────────────────────────────────────────────────────

class _QuizResultsView extends ConsumerWidget {
  final QuizState quizState;
  final VoidCallback onBackToSummaries;

  const _QuizResultsView({
    required this.quizState,
    required this.onBackToSummaries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = quizState.score;
    final quiz = quizState.quiz;
    final questions = quiz?.questions ?? [];

    // Determine score color
    final pct = score?.percentage ?? 0;
    Color scoreColor;
    if (pct >= 80) {
      scoreColor = AppColors.lightTealAccent;
    } else if (pct >= 50) {
      scoreColor = AppColors.lightAmberAccent;
    } else {
      scoreColor = AppColors.lightDestructive;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ─── Score display ───
          Text(
            loc.t('quiz.resultsTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Large score circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.1),
              border: Border.all(color: scoreColor, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.t('quiz.percentage',
                        args: {'percentage': pct.toStringAsFixed(0)}),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  if (score != null)
                    Text(
                      loc.t('quiz.scoreDisplay', args: {
                        'score': score.score.toStringAsFixed(1),
                        'maxScore': score.maxScore.toStringAsFixed(1),
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Percentage bar ───
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: scoreColor.withValues(alpha: 0.15),
              color: scoreColor,
              minHeight: 12,
            ),
          ),

          const SizedBox(height: 32),

          // ─── Per-question review ───
          if (questions.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  loc.t('quiz.reviewAnswers'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final userAnswer = quizState.answers[index];
              final correctAnswer = question.correctAnswer;
              final isCorrect =
                  userAnswer != null && userAnswer == correctAnswer;

              return _ReviewQuestionCard(
                questionIndex: index,
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer,
                isCorrect: isCorrect,
              );
            }),
          ],

          const SizedBox(height: 24),

          // ─── Back button ───
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBackToSummaries,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(loc.t('quiz.backToSummaries')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightOcean,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Review Question Card
// ────────────────────────────────────────────────────────────────

class _ReviewQuestionCard extends StatelessWidget {
  final int questionIndex;
  final QuizQuestion question;
  final String? userAnswer;
  final String? correctAnswer;
  final bool isCorrect;

  const _ReviewQuestionCard({
    required this.questionIndex,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.lightTealAccent
                        : AppColors.lightDestructive,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.t('quiz.reviewQuestion',
                        args: {'index': '${questionIndex + 1}'}),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCorrect
                          ? AppColors.lightTealAccent
                          : AppColors.lightDestructive,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            Text(
              question.question,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // User answer
            if (userAnswer != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('quiz.yourAnswer'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.lightTealAccent
                                .withValues(alpha: 0.1)
                            : AppColors.lightDestructive
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userAnswer!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCorrect
                              ? AppColors.lightTealAccent
                              : AppColors.lightDestructive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Correct answer (if wrong)
            if (!isCorrect && correctAnswer != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('quiz.correctAnswerLabel'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightTealAccent
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        correctAnswer!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTealAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

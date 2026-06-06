import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';
import '../shared/stat_card.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';
import '../shared/empty_state.dart';
import '../shared/countdown_timer.dart';

// ────────────────────────────────────────────────────────────
// Student Dashboard Home Screen
// ────────────────────────────────────────────────────────────

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(studentDashboardControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(studentDashboardControllerProvider.notifier)
          .refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Welcome Section ───
          SliverToBoxAdapter(child: _WelcomeSection(user: authState.user)),

          // ─── Quick Stats ───
          SliverToBoxAdapter(
            child: _QuickStatsSection(dashboard: dashboard),
          ),

          // ─── Upcoming Quizzes ───
          SliverToBoxAdapter(
            child: _UpcomingQuizzesSection(dashboard: dashboard),
          ),

          // ─── Recent Scores ───
          SliverToBoxAdapter(
            child: _RecentScoresSection(dashboard: dashboard),
          ),

          // ─── Recent Summaries ───
          SliverToBoxAdapter(
            child: _RecentSummariesSection(dashboard: dashboard),
          ),

          // ─── Quick Actions ───
          SliverToBoxAdapter(child: _QuickActionsSection()),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Welcome Section
// ────────────────────────────────────────────────────────────

class _WelcomeSection extends StatelessWidget {
  final UserProfile? user;
  const _WelcomeSection({this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    final now = DateTime.now();
    final dateStr = loc.isRTL
        ? DateFormat(AppConstants.dateFormatAr, 'ar').format(now)
        : DateFormat(AppConstants.dateFormatEn).format(now);

    final greeting = _getGreeting(loc);
    final userName = user?.name ?? loc.t('roles.student');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting، $userName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    if (hour < 12) return loc.t('student.goodMorning');
    if (hour < 17) return loc.t('student.goodAfternoon');
    return loc.t('student.goodEvening');
  }
}

// ────────────────────────────────────────────────────────────
// Quick Stats Section
// ────────────────────────────────────────────────────────────

class _QuickStatsSection extends StatelessWidget {
  final DashboardState dashboard;
  const _QuickStatsSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isLoading = dashboard.isAnyLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: 3 stat cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: LucideIcons.fileText,
                  title: loc.t('student.statSummaries'),
                  value: isLoading ? '—' : '${dashboard.totalSummaries}',
                  accentColor: AppColors.lightOcean,
                  isLoading: dashboard.isLoadingSummaries,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.helpCircle,
                  title: loc.t('student.quizzesTitle'),
                  value: isLoading ? '—' : '${dashboard.quizCount}',
                  accentColor: AppColors.lightTealAccent,
                  isLoading: dashboard.isLoadingQuizzes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.trendingUp,
                  title: loc.t('student.statAvgPerformance'),
                  value: isLoading
                      ? '—'
                      : '${dashboard.averageScore.toStringAsFixed(0)}%',
                  accentColor: AppColors.lightAmberAccent,
                  isLoading: dashboard.isLoadingScores,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: 3 stat cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: LucideIcons.checkCircle,
                  title: loc.t('attendance.rate'),
                  value: isLoading
                      ? '—'
                      : '${dashboard.attendanceRate.toStringAsFixed(0)}%',
                  accentColor: const Color(0xFF16A34A), // green
                  isLoading: dashboard.isLoadingAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.folderOpen,
                  title: loc.t('student.statFiles'),
                  value: isLoading ? '—' : '${dashboard.fileCount}',
                  accentColor: const Color(0xFF7C3AED), // purple
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.users,
                  title: loc.t('student.teachersTitle'),
                  value: isLoading ? '—' : '${dashboard.teacherCount}',
                  accentColor: const Color(0xFFEC4899), // pink
                  isLoading: dashboard.isLoadingTeachers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Upcoming Quizzes Section
// ────────────────────────────────────────────────────────────

class _UpcomingQuizzesSection extends StatelessWidget {
  final DashboardState dashboard;
  const _UpcomingQuizzesSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Show loading
    if (dashboard.isLoadingQuizzes) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.scheduledQuizzes')),
            const SizedBox(height: 12),
            const LoadingShimmerCardBlock(),
          ],
        ),
      );
    }

    // Show error
    if (dashboard.quizzesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.scheduledQuizzes')),
            SectionErrorBoundary(
              message: dashboard.quizzesError,
              onRetry: () {
                // Controller is accessed via provider in parent
              },
            ),
          ],
        ),
      );
    }

    // Filter upcoming quizzes (published, future)
    final now = DateTime.now();
    final upcoming = dashboard.quizzes
        .where((q) =>
            (q.isPublished ?? false) &&
            q.createdAt.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: loc.t('student.scheduledQuizzes')),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            EmptyState(
              icon: LucideIcons.calendarClock,
              title: loc.t('student.noQuizzes'),
              description: loc.t('student.scheduledQuizzes'),
              compact: true,
            )
          else
            ...upcoming.take(3).map((quiz) => _QuizCard(quiz: quiz)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Recent Scores Section
// ────────────────────────────────────────────────────────────

class _RecentScoresSection extends StatelessWidget {
  final DashboardState dashboard;
  const _RecentScoresSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (dashboard.isLoadingScores) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.latestResults')),
            const SizedBox(height: 12),
            const LoadingShimmerCardBlock(),
          ],
        ),
      );
    }

    if (dashboard.scoresError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.latestResults')),
            SectionErrorBoundary(message: dashboard.scoresError),
          ],
        ),
      );
    }

    final recentScores = dashboard.scores.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayed = recentScores.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: loc.t('student.latestResults')),
          const SizedBox(height: 8),
          if (displayed.isEmpty)
            EmptyState(
              icon: LucideIcons.barChart3,
              title: loc.t('student.noResultsYet'),
              compact: true,
            )
          else
            ...displayed.map((score) => _ScoreCard(score: score)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Recent Summaries Section
// ────────────────────────────────────────────────────────────

class _RecentSummariesSection extends StatelessWidget {
  final DashboardState dashboard;
  const _RecentSummariesSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (dashboard.isLoadingSummaries) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.latestSummaries')),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: LoadingShimmerCardBlock()),
                SizedBox(width: 12),
                Expanded(child: LoadingShimmerCardBlock()),
              ],
            ),
          ],
        ),
      );
    }

    if (dashboard.summariesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: loc.t('student.latestSummaries')),
            SectionErrorBoundary(message: dashboard.summariesError),
          ],
        ),
      );
    }

    final recentSummaries = dashboard.summaries.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayed = recentSummaries.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: loc.t('student.latestSummaries')),
          const SizedBox(height: 8),
          if (displayed.isEmpty)
            EmptyState(
              icon: LucideIcons.fileText,
              title: loc.t('student.noSummariesYet'),
              compact: true,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: displayed.length,
              itemBuilder: (context, index) {
                return _SummaryCard(summary: displayed[index]);
              },
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Quick Actions Section
// ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: loc.t('student.quickActions')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.fileText,
                  label: loc.t('student.createSummaryBtn'),
                  gradient: LinearGradient(
                    colors: [
                      oceanColor,
                      oceanColor.withValues(alpha: 0.8),
                    ],
                  ),
                  onTap: () {
                    // Navigate to create summary
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.helpCircle,
                  label: loc.t('student.createQuiz'),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealAccent(brightness),
                      AppColors.tealAccent(brightness).withValues(alpha: 0.8),
                    ],
                  ),
                  onTap: () {
                    // Navigate to take quiz
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: LucideIcons.calendarDays,
                  label: loc.t('nav.calendar'),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.amberAccent(brightness),
                      AppColors.amberAccent(brightness).withValues(alpha: 0.8),
                    ],
                  ),
                  onTap: () {
                    // Navigate to schedule/calendar
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Section Title
// ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Quiz Card
// ────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    // For scheduled quizzes, use createdAt as a proxy for scheduled time
    // In a real app, Quiz would have a `scheduledAt` field
    final scheduledDate = quiz.createdAt;
    final isUpcoming = scheduledDate.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: () {
          // Navigate to quiz details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightTealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.helpCircle,
                  size: 22,
                  color: AppColors.lightTealAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.t('common.questions') +
                          ': ${quiz.questions?.length ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpcoming)
                CountdownTimer(
                  target: scheduledDate,
                  compact: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Score Card
// ────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final Score score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    final percentage = score.percentage;
    final barColor = _scoreColor(percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: () {
          // Navigate to score details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.t('quiz.resultsTitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${score.score.toStringAsFixed(0)}/${score.maxScore.toStringAsFixed(0)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double pct) {
    if (pct >= 80) return const Color(0xFF16A34A); // green
    if (pct >= 60) return AppColors.lightAmberAccent; // amber
    return const Color(0xFFDC2626); // red
  }
}

// ────────────────────────────────────────────────────────────
// Summary Card
// ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final Summary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sourceType = summary.sourceFileType?.toUpperCase() ?? 'TXT';
    final sourceIcon = _fileTypeIcon(summary.sourceFileType);

    return Card(
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: () {
          // Navigate to summary details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(sourceIcon, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sourceType,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                summary.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                DateFormat(AppConstants.dateFormatAr).format(summary.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _fileTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'docx':
      case 'doc':
        return LucideIcons.fileType;
      case 'pptx':
      case 'ppt':
        return LucideIcons.presentation;
      case 'txt':
        return LucideIcons.fileCode;
      default:
        return LucideIcons.file;
    }
  }
}

// ────────────────────────────────────────────────────────────
// Quick Action Button
// ────────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: AppTheme.borderRadiusGeometry,
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppTheme.borderRadiusGeometry,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

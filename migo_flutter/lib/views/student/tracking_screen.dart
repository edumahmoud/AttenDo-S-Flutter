import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../i18n/app_localizations.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ────────────────────────────────────────────────────────────────
// Tracking Screen
// ────────────────────────────────────────────────────────────────

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(trackingControllerProvider.notifier).fetchPerformanceData();
    _refreshController.refreshCompleted();
  }

  // ─── Performance Level ───

  String _performanceLevel(double score, AppLocalizations loc) {
    if (score > 85) return loc.t('student.trackingAdvanced');
    if (score > 75) return loc.t('student.trackingOnTrack');
    if (score > 65) return loc.t('student.trackingNeedsAttention');
    if (score > 50) return loc.t('student.trackingOnTrack');
    return loc.t('student.trackingAtRisk');
  }

  Color _performanceLevelColor(double score) {
    if (score > 85) return const Color(0xFF10B981); // emerald
    if (score > 75) return const Color(0xFF0D9488); // teal
    if (score > 65) return const Color(0xFFF59E0B); // amber
    if (score > 50) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red
  }

  // ─── Risk Level ───

  String _riskLabel(RiskLevel level, AppLocalizations loc) {
    switch (level) {
      case RiskLevel.low:
        return loc.t('student.trackingOnTrack');
      case RiskLevel.medium:
        return loc.t('student.trackingNeedsAttention');
      case RiskLevel.high:
        return loc.t('student.trackingAtRisk');
      case RiskLevel.critical:
        return loc.t('student.trackingAtRisk');
    }
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF10B981);
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFF97316);
      case RiskLevel.critical:
        return const Color(0xFFEF4444);
    }
  }

  String _riskDescription(RiskLevel level, AppLocalizations loc) {
    switch (level) {
      case RiskLevel.low:
        return 'أداؤك جيد ومستقر، استمر على هذا المنوال';
      case RiskLevel.medium:
        return 'هناك بعض المؤشرات التي تحتاج متابعة لتحسين مستواك';
      case RiskLevel.high:
        return 'أداؤك يحتاج إلى تحسين عاجل في بعض الجوانب';
      case RiskLevel.critical:
        return 'أداؤك في مستوى متدنٍّ ويحتاج تدخلاً فورياً';
    }
  }

  // ─── Growth Trend ───

  String _growthLabel(GrowthTrend trend, AppLocalizations loc) {
    switch (trend) {
      case GrowthTrend.improving:
        return 'تتحسن';
      case GrowthTrend.stable:
        return 'مستقر';
      case GrowthTrend.declining:
        return 'في تراجع';
    }
  }

  IconData _growthIcon(GrowthTrend trend) {
    switch (trend) {
      case GrowthTrend.improving:
        return Icons.trending_up_rounded;
      case GrowthTrend.stable:
        return Icons.trending_flat_rounded;
      case GrowthTrend.declining:
        return Icons.trending_down_rounded;
    }
  }

  Color _growthColor(GrowthTrend trend) {
    switch (trend) {
      case GrowthTrend.improving:
        return const Color(0xFF10B981);
      case GrowthTrend.stable:
        return const Color(0xFF0D9488);
      case GrowthTrend.declining:
        return const Color(0xFFEF4444);
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(trackingControllerProvider);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: _buildHeader(context, loc, theme),
              ),

              // ─── Error ───
              if (state.error != null && state.performanceData.isEmpty)
                SliverFillRemaining(
                  child: SectionErrorBoundary(
                    message: state.error,
                    onRetry: () => ref
                        .read(trackingControllerProvider.notifier)
                        .fetchPerformanceData(),
                  ),
                ),

              // ─── Loading ───
              if (state.isLoading && state.performanceData.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LoadingShimmerCardBlock(),
                      ),
                      childCount: 5,
                    ),
                  ),
                ),

              // ─── Content ───
              if (!state.isLoading || state.performanceData.isNotEmpty) ...[
                // Overall Performance Card
                SliverToBoxAdapter(
                  child: _OverallPerformanceCard(
                    score: state.overallScore,
                    attendanceRate: state.overallAttendanceRate,
                    assignmentRate: state.overallAssignmentRate,
                    levelLabel: _performanceLevel(state.overallScore, loc),
                    levelColor: _performanceLevelColor(state.overallScore),
                  ),
                ),

                // Risk + Growth + Efficiency row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Risk Level
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.shield_rounded,
                            title: 'مستوى المخاطر',
                            value: _riskLabel(state.riskLevel, loc),
                            description: _riskDescription(state.riskLevel, loc),
                            accentColor: _riskColor(state.riskLevel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Growth Trend
                        Expanded(
                          child: _InfoCard(
                            icon: _growthIcon(state.growthTrend),
                            title: 'اتجاه النمو',
                            value: _growthLabel(state.growthTrend, loc),
                            description: state.growthTrend == GrowthTrend.improving
                                ? 'أداؤك في تحسن مستمر'
                                : state.growthTrend == GrowthTrend.stable
                                    ? 'أداؤك ثابت دون تغير كبير'
                                    : 'أداؤك في تراجع ويحتاج اهتمام',
                            accentColor: _growthColor(state.growthTrend),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Efficiency Card
                SliverToBoxAdapter(
                  child: _EfficiencyCard(
                    performanceScore: state.overallScore,
                    attendanceRate: state.overallAttendanceRate,
                    assignmentRate: state.overallAssignmentRate,
                  ),
                ),

                // Discipline Score Card
                SliverToBoxAdapter(
                  child: _DisciplineCard(
                    disciplineScore: state.disciplineScore,
                    attendanceRate: state.overallAttendanceRate,
                    assignmentRate: state.overallAssignmentRate,
                  ),
                ),

                // Attendance Analysis Section
                SliverToBoxAdapter(
                  child: _AttendanceSection(
                    overallRate: state.overallAttendanceRate,
                    subjectPerformances: state.subjectWisePerformance,
                  ),
                ),

                // Per-Subject Performance
                if (state.subjectWisePerformance.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SubjectPerformanceList(
                      subjects: state.subjectWisePerformance,
                    ),
                  ),

                // Performance Chart
                SliverToBoxAdapter(
                  child: _PerformanceChart(
                    performanceData: state.performanceData,
                  ),
                ),

                // Performance Distribution Pie Chart
                SliverToBoxAdapter(
                  child: _PerformancePieChart(
                    subjects: state.subjectWisePerformance,
                  ),
                ),

                // Activity Timeline
                SliverToBoxAdapter(
                  child: _ActivityTimeline(
                    performanceData: state.performanceData,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('student.trackingTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.t('student.trackingSubtitle'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Overall Performance Card
// ────────────────────────────────────────────────────────────────

class _OverallPerformanceCard extends StatelessWidget {
  final double score;
  final double attendanceRate;
  final double assignmentRate;
  final String levelLabel;
  final Color levelColor;

  const _OverallPerformanceCard({
    required this.score,
    required this.attendanceRate,
    required this.assignmentRate,
    required this.levelLabel,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          // ─── Circular progress + level badge ───
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: levelColor,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: levelColor,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        levelLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: levelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الأداء العام',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ─── Score breakdown ───
          Row(
            children: [
              _ScoreBreakdownItem(
                label: 'الاختبارات',
                value: 35,
                color: AppColors.lightOcean,
              ),
              _ScoreBreakdownItem(
                label: 'الحضور',
                value: 20,
                color: const Color(0xFF10B981),
              ),
              _ScoreBreakdownItem(
                label: 'الالتزام',
                value: 15,
                color: const Color(0xFFF59E0B),
              ),
              _ScoreBreakdownItem(
                label: 'الجودة',
                value: 30,
                color: AppColors.lightTealAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreBreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Info Card (Risk / Growth)
// ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color accentColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Efficiency Card
// ────────────────────────────────────────────────────────────────

class _EfficiencyCard extends StatelessWidget {
  final double performanceScore;
  final double attendanceRate;
  final double assignmentRate;

  const _EfficiencyCard({
    required this.performanceScore,
    required this.attendanceRate,
    required this.assignmentRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effort = (attendanceRate * 0.5 + assignmentRate * 0.5).clamp(0, 100);
    final ratio = effort > 0 ? performanceScore / effort : 0.0;

    String interpretation;
    Color accent;
    if (ratio > 1.1) {
      interpretation = 'أداؤك أعلى من جهدك — استثمار ممتاز للوقت';
      accent = const Color(0xFF10B981);
    } else if (ratio > 0.9) {
      interpretation = 'أداؤك متناسب مع جهدك — استمر بنفس الوتيرة';
      accent = const Color(0xFF0D9488);
    } else {
      interpretation = 'أداؤك أقل من جهدك — قد تحتاج لتغيير استراتيجية الدراسة';
      accent = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.speed_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'الكفاءة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gauge bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (ratio.clamp(0, 1.5) / 1.5),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            interpretation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Discipline Score Card
// ────────────────────────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  final double disciplineScore;
  final double attendanceRate;
  final double assignmentRate;

  const _DisciplineCard({
    required this.disciplineScore,
    required this.attendanceRate,
    required this.assignmentRate,
  });

  Color _scoreColor(double score) {
    if (score > 85) return const Color(0xFF10B981);
    if (score > 70) return const Color(0xFF0D9488);
    if (score > 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(disciplineScore);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified_user_rounded, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                'درجة الانضباط',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${disciplineScore.toStringAsFixed(0)} / 100',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Breakdown bars
          _DisciplineBar(
            label: 'انتظام الحضور',
            value: attendanceRate,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 8),
          _DisciplineBar(
            label: 'التسليم في الوقت',
            value: assignmentRate,
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 8),
          _DisciplineBar(
            label: 'احترام المواعيد',
            value: disciplineScore,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class _DisciplineBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DisciplineBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Attendance Section
// ────────────────────────────────────────────────────────────────

class _AttendanceSection extends StatelessWidget {
  final double overallRate;
  final List<SubjectPerformance> subjectPerformances;

  const _AttendanceSection({
    required this.overallRate,
    required this.subjectPerformances,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.t('student.trackingAttendanceOverview'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _attendanceColor(overallRate).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${overallRate.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _attendanceColor(overallRate),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Per-subject attendance
          if (subjectPerformances.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  loc.t('student.trackingNoAttendanceData'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...subjectPerformances.map((sp) => _SubjectAttendanceRow(
                  subjectName: sp.subjectName,
                  attendanceRate: sp.attendanceRate,
                )),
        ],
      ),
    );
  }

  Color _attendanceColor(double rate) {
    if (rate > 85) return const Color(0xFF10B981);
    if (rate > 70) return const Color(0xFF0D9488);
    if (rate > 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _SubjectAttendanceRow extends StatelessWidget {
  final String subjectName;
  final double attendanceRate;

  const _SubjectAttendanceRow({
    required this.subjectName,
    required this.attendanceRate,
  });

  Color _color(double rate) {
    if (rate > 85) return const Color(0xFF10B981);
    if (rate > 70) return const Color(0xFF0D9488);
    if (rate > 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(attendanceRate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              subjectName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Background bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Present portion (green)
                  FractionallySizedBox(
                    widthFactor: (attendanceRate / 100).clamp(0, 1),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${attendanceRate.toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Per-Subject Performance List
// ────────────────────────────────────────────────────────────────

class _SubjectPerformanceList extends StatelessWidget {
  final List<SubjectPerformance> subjects;

  const _SubjectPerformanceList({required this.subjects});

  Color _levelColor(String? level) {
    switch (level) {
      case 'excellent':
        return const Color(0xFF10B981);
      case 'good':
        return const Color(0xFF0D9488);
      case 'average':
        return const Color(0xFFF59E0B);
      case 'below_average':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF0D9488);
    }
  }

  String _levelLabel(String? level) {
    switch (level) {
      case 'excellent':
        return 'ممتاز';
      case 'good':
        return 'جيد جداً';
      case 'average':
        return 'متوسط';
      case 'below_average':
        return 'ضعيف';
      default:
        return 'جيد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightOcean.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 18,
                  color: AppColors.lightOcean,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'الأداء حسب المقرر',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...subjects.map((sp) {
            final color = _levelColor(sp.performanceLevel);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: sp.averageScore / 100,
                          strokeWidth: 5,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: color,
                        ),
                        Center(
                          child: Text(
                            sp.averageScore.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sp.subjectName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _levelLabel(sp.performanceLevel),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _SubjectMetric(
                                label: 'اختبارات',
                                value: '${sp.averageScore.toStringAsFixed(0)}%'),
                            _SubjectMetric(
                                label: 'حضور',
                                value: '${sp.attendanceRate.toStringAsFixed(0)}%'),
                            _SubjectMetric(
                                label: 'التزام',
                                value:
                                    '${sp.totalAssignments > 0 ? ((sp.assignmentsCompleted / sp.totalAssignments) * 100).toStringAsFixed(0) : '-'}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SubjectMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SubjectMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Performance Area Chart (fl_chart)
// ────────────────────────────────────────────────────────────────

class _PerformanceChart extends StatelessWidget {
  final List<StudentPerformance> performanceData;

  const _PerformanceChart({required this.performanceData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build monthly data points from performance records
    final Map<int, double> monthlyScores = {};
    for (final p in performanceData) {
      final month = (p.lastCalculated ?? p.createdAt).month;
      final existing = monthlyScores[month];
      if (existing != null) {
        monthlyScores[month] = (existing + (p.averageScore ?? 0)) / 2;
      } else {
        monthlyScores[month] = p.averageScore ?? 0;
      }
    }

    final sortedMonths = monthlyScores.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedMonths.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyScores[sortedMonths[i]]!));
    }

    // If no data, show placeholder
    if (spots.isEmpty) {
      spots.addAll([
        const FlSpot(0, 50),
        const FlSpot(1, 60),
        const FlSpot(2, 55),
        const FlSpot(3, 65),
        const FlSpot(4, 70),
        const FlSpot(5, 75),
      ]);
    }

    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightOcean.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: AppColors.lightOcean,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'اتجاه الأداء الشهري',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        final monthIdx =
                            sortedMonths.isNotEmpty && idx < sortedMonths.length
                                ? sortedMonths[idx] - 1
                                : idx % 12;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[monthIdx.clamp(0, 11)],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: AppColors.lightOcean,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.lightOcean,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.lightOcean.withValues(alpha: 0.25),
                          AppColors.lightOcean.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipColor: (_) => AppColors.lightOcean,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}%',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Performance Distribution Pie Chart
// ────────────────────────────────────────────────────────────────

class _PerformancePieChart extends StatelessWidget {
  final List<SubjectPerformance> subjects;

  const _PerformancePieChart({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Categorize subjects by performance level
    int excellent = 0, good = 0, average = 0, belowAvg = 0;
    for (final sp in subjects) {
      if (sp.averageScore > 85)
        excellent++;
      else if (sp.averageScore > 70)
        good++;
      else if (sp.averageScore > 50)
        average++;
      else
        belowAvg++;
    }

    final total = subjects.length;
    if (total == 0) {
      excellent = 3;
      good = 5;
      average = 2;
      belowAvg = 1;
    }

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: excellent.toDouble(),
        color: const Color(0xFF10B981),
        title: excellent > 0 ? '$excellent' : '',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: good.toDouble(),
        color: const Color(0xFF0D9488),
        title: good > 0 ? '$good' : '',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: average.toDouble(),
        color: const Color(0xFFF59E0B),
        title: average > 0 ? '$average' : '',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      PieChartSectionData(
        value: belowAvg.toDouble(),
        color: const Color(0xFFEF4444),
        title: belowAvg > 0 ? '$belowAvg' : '',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightTealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 18,
                  color: AppColors.lightTealAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'توزيع مستويات الأداء',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFF10B981), label: 'ممتاز'),
              _LegendItem(color: const Color(0xFF0D9488), label: 'جيد جداً'),
              _LegendItem(color: const Color(0xFFF59E0B), label: 'متوسط'),
              _LegendItem(color: const Color(0xFFEF4444), label: 'ضعيف'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Activity Timeline
// ────────────────────────────────────────────────────────────────

class _ActivityTimeline extends StatefulWidget {
  final List<StudentPerformance> performanceData;

  const _ActivityTimeline({required this.performanceData});

  @override
  State<_ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<_ActivityTimeline> {
  String _selectedFilter = 'all';

  static const _filterTypes = [
    ('all', 'الكل', Icons.list_rounded),
    ('quiz', 'اختبارات', Icons.quiz_rounded),
    ('attendance', 'حضور', Icons.event_available_rounded),
    ('assignment', 'مهام', Icons.assignment_rounded),
    ('grading', 'تقييم', Icons.grade_rounded),
    ('risk', 'مخاطر', Icons.warning_rounded),
  ];

  List<_ActivityItem> _buildActivities() {
    final items = <_ActivityItem>[];
    for (final p in widget.performanceData) {
      final date = p.lastCalculated ?? p.updatedAt;
      if (p.quizzesTaken != null && p.quizzesTaken! > 0) {
        items.add(_ActivityItem(
          type: 'quiz',
          description: 'أكمل ${p.quizzesTaken} اختبار',
          date: date,
          subjectId: p.subjectId,
          color: AppColors.lightOcean,
          icon: Icons.quiz_rounded,
        ));
      }
      if (p.attendanceRate != null) {
        items.add(_ActivityItem(
          type: 'attendance',
          description: 'نسبة الحضور ${p.attendanceRate!.toStringAsFixed(0)}%',
          date: date,
          subjectId: p.subjectId,
          color: const Color(0xFF10B981),
          icon: Icons.event_available_rounded,
        ));
      }
      if (p.assignmentsCompleted != null && p.assignmentsCompleted! > 0) {
        items.add(_ActivityItem(
          type: 'assignment',
          description: 'أكمل ${p.assignmentsCompleted} مهمة',
          date: date,
          subjectId: p.subjectId,
          color: AppColors.lightTealAccent,
          icon: Icons.assignment_turned_in_rounded,
        ));
      }
      if (p.averageScore != null) {
        items.add(_ActivityItem(
          type: 'grading',
          description: 'معدل الدرجات ${p.averageScore!.toStringAsFixed(0)}%',
          date: date,
          subjectId: p.subjectId,
          color: const Color(0xFFF59E0B),
          icon: Icons.grade_rounded,
        ));
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  String _formatDate(DateTime date, AppLocalizations loc) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allActivities = _buildActivities();
    final filtered = _selectedFilter == 'all'
        ? allActivities
        : allActivities.where((a) => a.type == _selectedFilter).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightAmberAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 18,
                  color: AppColors.lightAmberAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'سجل النشاط',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _filterTypes.map((f) {
              final isSelected = _selectedFilter == f.$1;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.$3, size: 14, color: isSelected ? Colors.white : null),
                    const SizedBox(width: 4),
                    Text(f.$2),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = f.$1),
                selectedColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Activity list
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  loc.t('common.noData'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...filtered.take(10).map((item) => _ActivityTile(
                  item: item,
                  dateLabel: _formatDate(item.date, loc),
                )),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String type;
  final String description;
  final DateTime date;
  final String? subjectId;
  final Color color;
  final IconData icon;

  const _ActivityItem({
    required this.type,
    required this.description,
    required this.date,
    this.subjectId,
    required this.color,
    required this.icon,
  });
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final String dateLabel;

  const _ActivityTile({
    required this.item,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 16, color: item.color),
              ),
              Container(
                width: 2,
                height: 16,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.subjectId != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.subjectId!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

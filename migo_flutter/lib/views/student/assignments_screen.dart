import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../controllers/controllers.dart';
import '../../i18n/app_localizations.dart';
import '../../models/models.dart';
import '../shared/empty_state.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ─── Filter enum ───

enum AssignmentFilter { all, pending, submitted, graded, overdue }

enum AssignmentSort { dueDate, subject }

// ─── Assignments Screen ───

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  AssignmentFilter _filter = AssignmentFilter.all;
  AssignmentSort _sort = AssignmentSort.dueDate;
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(assignmentsControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(assignmentsControllerProvider.notifier).fetchAssignments(),
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(child: _buildHeader(loc, state)),

              // ─── Filter Chips ───
              SliverToBoxAdapter(child: _buildFilterChips(loc)),

              // ─── Content ───
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LoadingShimmerCardBlock(),
                        SizedBox(height: 12),
                        LoadingShimmerCardBlock(),
                      ],
                    ),
                  ),
                )
              else if (state.error != null)
                SliverToBoxAdapter(
                  child: SectionErrorBoundary(
                    message: state.error,
                    onRetry: () => ref
                        .read(assignmentsControllerProvider.notifier)
                        .fetchAssignments(),
                  ),
                )
              else if (_filteredAssignments(state).isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: loc.t('assignments.noAssignments'),
                    description: loc.t('assignments.noAssignments'),
                  ),
                )
              else
                _buildGroupedAssignments(loc, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, AssignmentsState state) {
    final theme = Theme.of(context);
    final count = state.assignments.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${loc.t('assignments.title')} ($count)',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildSortButton(loc),
        ],
      ),
    );
  }

  Widget _buildSortButton(AppLocalizations loc) {
    final theme = Theme.of(context);

    return PopupMenuButton<AssignmentSort>(
      icon: Icon(
        Icons.sort_rounded,
        color: theme.colorScheme.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusGeometry,
      ),
      onSelected: (value) => setState(() => _sort = value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AssignmentSort.dueDate,
          child: Row(
            children: [
              Icon(
                _sort == AssignmentSort.dueDate
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(loc.t('assignments.dueDate')),
            ],
          ),
        ),
        PopupMenuItem(
          value: AssignmentSort.subject,
          child: Row(
            children: [
              Icon(
                _sort == AssignmentSort.subject
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(loc.t('nav.subjects')),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Filter Chips ───

  Widget _buildFilterChips(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      (AssignmentFilter.all, loc.t('common.filter')),
      (AssignmentFilter.pending, loc.t('assignments.pending')),
      (AssignmentFilter.submitted, loc.t('assignments.submitted')),
      (AssignmentFilter.graded, loc.t('assignments.graded')),
      (AssignmentFilter.overdue, loc.t('assignments.late')),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _filter == filter;

          return FilterChip(
            selected: isSelected,
            label: Text(label),
            onSelected: (_) => setState(() => _filter = filter),
            selectedColor: colorScheme.primary.withValues(alpha: 0.15),
            checkmarkColor: colorScheme.primary,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
          );
        },
      ),
    );
  }

  // ─── Filtering & Grouping ───

  List<Assignment> _filteredAssignments(AssignmentsState state) {
    var list = List<Assignment>.from(state.assignments);

    switch (_filter) {
      case AssignmentFilter.all:
        break;
      case AssignmentFilter.pending:
        list = state.pendingAssignments;
        break;
      case AssignmentFilter.submitted:
        list = state.submittedAssignments.where((a) {
          final sub = _activeSubmission(a);
          return sub != null && sub.grade == null;
        }).toList();
        break;
      case AssignmentFilter.graded:
        list = state.submittedAssignments.where((a) {
          final sub = _activeSubmission(a);
          return sub != null && sub.grade != null;
        }).toList();
        break;
      case AssignmentFilter.overdue:
        list = state.overdueAssignments;
        break;
    }

    // Sort
    if (_sort == AssignmentSort.dueDate) {
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      list.sort((a, b) => a.subjectId.compareTo(b.subjectId));
    }

    return list;
  }

  Submission? _activeSubmission(Assignment a) {
    final subs = a.submissions ?? [];
    if (subs.isEmpty) return null;
    return subs.first;
  }

  /// Derive a submission status string from an assignment.
  String _submissionStatus(Assignment a) {
    final sub = _activeSubmission(a);
    if (sub == null || sub.submittedAt == null) return 'not_submitted';
    if (sub.grade != null) return 'graded';
    return 'submitted';
  }

  // ─── Grouped List ───

  Widget _buildGroupedAssignments(AppLocalizations loc, AssignmentsState state) {
    final assignments = _filteredAssignments(state);

    if (_sort == AssignmentSort.subject) {
      // Group by subjectId
      final groups = <String, List<Assignment>>{};
      for (final a in assignments) {
        groups.putIfAbsent(a.subjectId, () => []).add(a);
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subjectId = groups.keys.elementAt(index);
            final group = groups[subjectId]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    subjectId,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                ...group.map((a) => _buildAssignmentCard(loc, a)),
              ],
            );
          },
          childCount: groups.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildAssignmentCard(loc, assignments[index]),
        childCount: assignments.length,
      ),
    );
  }

  // ─── Assignment Card ───

  Widget _buildAssignmentCard(AppLocalizations loc, Assignment assignment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedIds.contains(assignment.id);
    final status = _submissionStatus(assignment);
    final sub = _activeSubmission(assignment);

    final isOverdue = assignment.dueDate != null &&
        assignment.dueDate!.isBefore(DateTime.now()) &&
        status == 'not_submitted';

    final isDueSoon = assignment.dueDate != null &&
        !isOverdue &&
        assignment.dueDate!.difference(DateTime.now()).inHours < 24 &&
        assignment.dueDate!.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: InkWell(
          onTap: () => _toggleExpand(assignment.id),
          borderRadius: AppTheme.borderRadiusGeometry,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top Row ───
                Row(
                  children: [
                    // Subject color indicator
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _subjectColor(assignment.subjectId),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            assignment.subjectId,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(loc, status, isOverdue),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),

                // ─── Due date & max score row ───
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: isOverdue
                          ? AppColors.lightDestructive
                          : isDueSoon
                              ? AppColors.lightAmberAccent
                              : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(assignment.dueDate, loc),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? AppColors.lightDestructive
                            : isDueSoon
                                ? AppColors.lightAmberAccent
                                : colorScheme.onSurfaceVariant,
                        fontWeight:
                            (isOverdue || isDueSoon) ? FontWeight.w600 : null,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${loc.t('assignments.late')})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightDestructive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (isDueSoon) ...[
                      const SizedBox(width: 6),
                      Text(
                        _countdown(assignment.dueDate!, loc),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.lightAmberAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (assignment.maxGrade != null)
                      Text(
                        '${loc.t('assignments.grade')}: ${assignment.maxGrade}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                // ─── Graded: score display ───
                if (status == 'graded' && sub != null && sub.grade != null) ...[
                  const SizedBox(height: 8),
                  _buildGradedScore(loc, sub, assignment.maxGrade),
                ],

                // ─── Expanded detail ───
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildExpandedDetail(loc, assignment, status, sub),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status Badge ───

  Widget _buildStatusBadge(AppLocalizations loc, String status, bool isOverdue) {
    final (label, fgColor, bgColor) = switch (status) {
      'not_submitted' => (
          isOverdue
              ? loc.t('assignments.late')
              : loc.t('assignments.pending'),
          isOverdue ? AppColors.lightDestructiveForeground : Colors.white,
          isOverdue ? AppColors.lightDestructive : AppColors.lightAmberAccent,
        ),
      'submitted' => (
          loc.t('assignments.submitted'),
          Colors.white,
          AppColors.lightOcean,
        ),
      'graded' => (
          loc.t('assignments.graded'),
          Colors.white,
          AppColors.lightTealAccent,
        ),
      _ => (
          loc.t('assignments.pending'),
          Colors.white,
          AppColors.lightAmberAccent,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Graded Score Bar ───

  Widget _buildGradedScore(
      AppLocalizations loc, Submission sub, double? maxGrade) {
    final theme = Theme.of(context);
    final maxVal = maxGrade ?? 100;
    final gradeVal = sub.grade ?? 0;
    final pct = (gradeVal / maxVal).clamp(0.0, 1.0);
    final isGood = pct >= 0.7;
    final isMedium = pct >= 0.5 && pct < 0.7;

    final barColor = isGood
        ? AppColors.lightTealAccent
        : isMedium
            ? AppColors.lightAmberAccent
            : AppColors.lightDestructive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${gradeVal.toStringAsFixed(1)} / ${maxVal.toStringAsFixed(1)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: barColor.withValues(alpha: 0.15),
            color: barColor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Expanded Detail ───

  Widget _buildExpandedDetail(
    AppLocalizations loc,
    Assignment assignment,
    String status,
    Submission? sub,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        if (assignment.description != null &&
            assignment.description!.isNotEmpty) ...[
          Text(
            loc.t('common.more'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assignment.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Due date & time
        if (assignment.dueDate != null) ...[
          _buildInfoRow(
            Icons.event_rounded,
            loc.t('assignments.dueDate'),
            DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en')
                .add_jm()
                .format(assignment.dueDate!),
            theme,
          ),
          const SizedBox(height: 8),
        ],

        // Max score
        if (assignment.maxGrade != null) ...[
          _buildInfoRow(
            Icons.grade_rounded,
            loc.t('assignments.grade'),
            '${assignment.maxGrade}',
            theme,
          ),
          const SizedBox(height: 12),
        ],

        const Divider(height: 1),
        const SizedBox(height: 12),

        // ─── Submission section ───
        if (status == 'not_submitted')
          _buildNotSubmittedSection(loc, assignment)
        else if (status == 'submitted')
          _buildSubmittedSection(loc, sub)
        else if (status == 'graded')
          _buildGradedSection(loc, sub),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Not Submitted ───

  Widget _buildNotSubmittedSection(AppLocalizations loc, Assignment assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSubmitDialog(loc, assignment),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(loc.t('assignments.submitAssignment')),
          ),
        ),
      ],
    );
  }

  // ─── Submitted ───

  Widget _buildSubmittedSection(AppLocalizations loc, Submission? sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.lightOcean),
            const SizedBox(width: 6),
            Text(
              loc.t('assignments.submitted'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.lightOcean,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (sub?.submittedAt != null) ...[
          const SizedBox(height: 6),
          Text(
            DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en')
                .add_jm()
                .format(sub!.submittedAt!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (sub?.content != null && sub!.content!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
            child: Text(
              sub.content ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (sub?.fileUrl != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              // Open file URL
            },
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  sub?.fileName ?? loc.t('files.download'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Graded ───

  Widget _buildGradedSection(AppLocalizations loc, Submission? sub) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_rounded,
                size: 18, color: AppColors.lightTealAccent),
            const SizedBox(width: 6),
            Text(
              loc.t('assignments.graded'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.lightTealAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (sub?.feedback != null && sub!.feedback!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            loc.t('common.more'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightTealAccent.withValues(alpha: 0.08),
              borderRadius: AppTheme.borderRadiusGeometry,
              border: Border.all(
                  color: AppColors.lightTealAccent.withValues(alpha: 0.2)),
            ),
            child: Text(
              sub.feedback ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Submit Dialog ───

  void _showSubmitDialog(AppLocalizations loc, Assignment assignment) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(assignmentsControllerProvider);

            return AlertDialog(
              title: Text(loc.t('assignments.submitAssignment')),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: loc.t('common.more'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // File picker integration
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: Text(loc.t('files.upload')),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      state.isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final success = await ref
                              .read(assignmentsControllerProvider.notifier)
                              .submitAssignment(
                                assignment.id,
                                content: contentController.text.trim().isEmpty
                                    ? null
                                    : contentController.text.trim(),
                              );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.t('assignments.submissionSuccess'),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.t('assignments.submissionError'),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('assignments.submit')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Helpers ───

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Color _subjectColor(String subjectId) {
    // Deterministic color from subjectId hash
    final hash = subjectId.hashCode;
    final colors = [
      AppColors.lightOcean,
      AppColors.lightTealAccent,
      AppColors.lightAmberAccent,
      AppColors.lightDestructive,
      AppColors.lightAccent,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatDueDate(DateTime? dueDate, AppLocalizations loc) {
    if (dueDate == null) return '--';
    return DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en').format(dueDate);
  }

  String _countdown(DateTime dueDate, AppLocalizations loc) {
    final diff = dueDate.difference(DateTime.now());
    if (diff.inHours <= 0) return '';
    if (diff.inHours < 24) {
      return loc.t('time.durationHours', args: {'n': '${diff.inHours}'});
    }
    return loc.t('time.durationDays', args: {'n': '${diff.inDays}'});
  }
}

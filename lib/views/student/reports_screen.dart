import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../i18n/app_localizations.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../shared/empty_state.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ─── Filter enum ───

enum ReportFilter { all, open, inProgress, resolved, closed }

// ────────────────────────────────────────────────────────────────
// Reports Screen
// ────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportFilter _filter = ReportFilter.all;
  String? _selectedReportId;

  // ─── Helpers ───

  String _relativeDate(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return loc.t('time.justNow');
    if (diff.inMinutes < 60) {
      return loc.t('time.minutesAgo', args: {'n': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return loc.t('time.hoursAgo', args: {'n': diff.inHours.toString()});
    }
    if (diff.inDays < 30) {
      return loc.t('time.daysAgo', args: {'n': diff.inDays.toString()});
    }
    return loc.t('time.monthsAgo', args: {'n': (diff.inDays ~/ 30).toString()});
  }

  IconData _reportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.bug:
        return Icons.bug_report_rounded;
      case ReportType.feature:
        return Icons.lightbulb_rounded;
      case ReportType.complaint:
        return Icons.flag_rounded;
      case ReportType.question:
        return Icons.help_rounded;
      case ReportType.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return AppColors.lightAmberAccent;
      case ReportStatus.inProgress:
        return AppColors.lightOcean;
      case ReportStatus.resolved:
        return AppColors.lightTealAccent;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations loc, ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return loc.t('reports.pending');
      case ReportStatus.inProgress:
        return loc.t('reports.inProgress');
      case ReportStatus.resolved:
        return loc.t('reports.resolved');
      case ReportStatus.closed:
        return loc.t('reports.dismissed');
    }
  }

  Color _typeColor(ReportType type) {
    switch (type) {
      case ReportType.bug:
        return AppColors.lightDestructive;
      case ReportType.feature:
        return AppColors.lightTealAccent;
      case ReportType.complaint:
        return AppColors.lightAmberAccent;
      case ReportType.question:
        return AppColors.lightOcean;
      case ReportType.other:
        return Colors.grey;
    }
  }

  List<Report> _filteredReports(List<Report> reports) {
    switch (_filter) {
      case ReportFilter.all:
        return reports;
      case ReportFilter.open:
        return reports.where((r) => r.status == ReportStatus.open).toList();
      case ReportFilter.inProgress:
        return reports.where((r) => r.status == ReportStatus.inProgress).toList();
      case ReportFilter.resolved:
        return reports.where((r) => r.status == ReportStatus.resolved).toList();
      case ReportFilter.closed:
        return reports.where((r) => r.status == ReportStatus.closed).toList();
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(reportsControllerProvider);

    // If a report is selected, show detail view
    if (_selectedReportId != null) {
      final report = state.reports
          .where((r) => r.id == _selectedReportId)
          .firstOrNull;
      if (report != null) {
        return _ReportDetailView(
          report: report,
          onBack: () => setState(() => _selectedReportId = null),
        );
      }
    }

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(reportsControllerProvider.notifier).fetchReports(),
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(child: _buildHeader(loc, state)),

              // ─── Filter Chips ───
              SliverToBoxAdapter(child: _buildFilterChips(loc)),

              // ─── Error ───
              if (state.reportsError != null && state.reports.isEmpty)
                SliverFillRemaining(
                  child: SectionErrorBoundary(
                    message: state.reportsError,
                    onRetry: () => ref
                        .read(reportsControllerProvider.notifier)
                        .fetchReports(),
                  ),
                ),

              // ─── Loading ───
              if (state.isLoadingReports && state.reports.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LoadingShimmerCardBlock(),
                      ),
                      childCount: 4,
                    ),
                  ),
                ),

              // ─── Empty state ───
              if (!state.isLoadingReports &&
                  state.reports.isEmpty &&
                  state.reportsError == null)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.report_outlined,
                    title: loc.t('reports.noReports'),
                    description: loc.t('reports.noReportsDesc'),
                    actionLabel: loc.t('reports.newReport'),
                    onAction: () => _showNewReportDialog(loc),
                  ),
                ),

              // ─── Reports list ───
              if (state.reports.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = _filteredReports(state.reports)[index];
                        return _ReportCard(
                          report: report,
                          statusColor: _statusColor(report.status),
                          statusLabel:
                              _statusLabel(loc, report.status),
                          typeIcon: _reportTypeIcon(report.type),
                          typeColor: _typeColor(report.type),
                          relativeDate:
                              _relativeDate(context, report.createdAt),
                          onTap: () => setState(
                              () => _selectedReportId = report.id),
                        );
                      },
                      childCount:
                          _filteredReports(state.reports).length,
                    ),
                  ),
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),

        // ─── FAB ───
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusGeometry,
            gradient: const LinearGradient(
              colors: [AppColors.lightOcean, AppColors.lightTealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightOcean.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'newReport',
            onPressed: () => _showNewReportDialog(loc),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              loc.t('reports.newReport'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, ReportsState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('reports.title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.t('reports.subtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.reports.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.reports.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Filter Chips ───

  Widget _buildFilterChips(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      (ReportFilter.all, loc.t('reports.all')),
      (ReportFilter.open, loc.t('reports.pending')),
      (ReportFilter.inProgress, loc.t('reports.inProgress')),
      (ReportFilter.resolved, loc.t('reports.resolved')),
      (ReportFilter.closed, loc.t('reports.dismissed')),
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
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
          );
        },
      ),
    );
  }

  // ─── New Report Dialog ───

  void _showNewReportDialog(AppLocalizations loc) {
    String selectedTargetType = 'comment';
    final targetIdController = TextEditingController();
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(reportsControllerProvider);
          return Directionality(
            textDirection: loc.textDirection,
            child: AlertDialog(
              title: Text(loc.t('reports.newReport')),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target type selector
                      Text(
                        loc.t('reports.targetType'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _targetTypeChip(
                            ctx: context,
                            label: loc.t('reports.targetComment'),
                            icon: Icons.comment_rounded,
                            value: 'comment',
                            groupValue: selectedTargetType,
                            onChanged: (v) => setState(
                                () => selectedTargetType = v ?? 'comment'),
                          ),
                          _targetTypeChip(
                            ctx: context,
                            label: loc.t('reports.targetMessage'),
                            icon: Icons.message_rounded,
                            value: 'message',
                            groupValue: selectedTargetType,
                            onChanged: (v) => setState(
                                () => selectedTargetType = v ?? 'comment'),
                          ),
                          _targetTypeChip(
                            ctx: context,
                            label: loc.t('reports.targetUser'),
                            icon: Icons.person_rounded,
                            value: 'user',
                            groupValue: selectedTargetType,
                            onChanged: (v) => setState(
                                () => selectedTargetType = v ?? 'comment'),
                          ),
                          _targetTypeChip(
                            ctx: context,
                            label: loc.t('reports.targetOther'),
                            icon: Icons.more_horiz_rounded,
                            value: 'other',
                            groupValue: selectedTargetType,
                            onChanged: (v) => setState(
                                () => selectedTargetType = v ?? 'comment'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target ID
                      TextField(
                        controller: targetIdController,
                        decoration: InputDecoration(
                          labelText: loc.t('reports.targetId'),
                          hintText: loc.t('reports.targetIdHint'),
                          prefixIcon: const Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reason
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: loc.t('reports.reason'),
                          hintText: loc.t('reports.reasonHint'),
                          prefixIcon: const Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: loc.t('reports.description'),
                          hintText: loc.t('reports.descriptionHint'),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Attachment (placeholder)
                      OutlinedButton.icon(
                        onPressed: () {
                          // File picker for attachments
                        },
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: Text(loc.t('reports.attachment')),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: state.isCreating
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: state.isCreating
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) return;
                          final success = await ref
                              .read(reportsControllerProvider.notifier)
                              .createReport(
                                targetType: selectedTargetType,
                                targetId: targetIdController.text.trim()
                                        .isEmpty
                                    ? 'unknown'
                                    : targetIdController.text.trim(),
                                reason: reasonController.text.trim(),
                                description: descController.text.trim()
                                        .isEmpty
                                    ? null
                                    : descController.text.trim(),
                              );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(loc.t('reports.reportSent'))),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(loc.t('reports.reportError'))),
                              );
                            }
                          }
                        },
                  child: state.isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('reports.submitReport')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _targetTypeChip({
    required BuildContext ctx,
    required String label,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    final theme = Theme.of(ctx);
    return ChoiceChip(
      avatar: Icon(icon, size: 16,
          color: isSelected ? theme.colorScheme.onPrimary : null),
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onChanged(value),
      selectedColor: theme.colorScheme.primary,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Report Card
// ────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Report report;
  final Color statusColor;
  final String statusLabel;
  final IconData typeIcon;
  final Color typeColor;
  final String relativeDate;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.statusColor,
    required this.statusLabel,
    required this.typeIcon,
    required this.typeColor,
    required this.relativeDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusGeometry,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top row: number badge + type icon + status ───
              Row(
                children: [
                  // Report number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          '#${report.id.substring(0, 6)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      report.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Description preview
              Text(
                report.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Date + unread indicator
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    relativeDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if ((report.responses?.length ?? 0) > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightOcean.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.reply_rounded,
                              size: 12, color: AppColors.lightOcean),
                          const SizedBox(width: 4),
                          Text(
                            '${report.responses!.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.lightOcean,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Report Detail View
// ────────────────────────────────────────────────────────────────

class _ReportDetailView extends ConsumerStatefulWidget {
  final Report report;
  final VoidCallback onBack;

  const _ReportDetailView({
    required this.report,
    required this.onBack,
  });

  @override
  ConsumerState<_ReportDetailView> createState() =>
      _ReportDetailViewState();
}

class _ReportDetailViewState extends ConsumerState<_ReportDetailView> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load messages for this report
    Future.microtask(() {
      ref
          .read(reportsControllerProvider.notifier)
          .fetchReportMessages(widget.report.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    ref.read(reportsControllerProvider.notifier).clearActiveReport();
    super.dispose();
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return AppColors.lightAmberAccent;
      case ReportStatus.inProgress:
        return AppColors.lightOcean;
      case ReportStatus.resolved:
        return AppColors.lightTealAccent;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  String _statusLabel(AppLocalizations loc, ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return loc.t('reports.pending');
      case ReportStatus.inProgress:
        return loc.t('reports.inProgress');
      case ReportStatus.resolved:
        return loc.t('reports.resolved');
      case ReportStatus.closed:
        return loc.t('reports.dismissed');
    }
  }

  String _relativeDate(DateTime date) {
    final loc = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return loc.t('time.justNow');
    if (diff.inMinutes < 60) {
      return loc.t('time.minutesAgo', args: {'n': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return loc.t('time.hoursAgo', args: {'n': diff.inHours.toString()});
    }
    return loc.t('time.daysAgo', args: {'n': diff.inDays.toString()});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(reportsControllerProvider);
    final report = widget.report;
    final messages = state.activeReportMessages;

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
          title: Text(loc.t('reports.detailTitle')),
        ),
        body: Column(
          children: [
            // ─── Report header ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${report.id.substring(0, 6)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(report.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(loc, report.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _relativeDate(report.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Responses Timeline ───
            if (report.responses != null && report.responses!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  loc.t('reports.responsesTitle'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...report.responses!.map((response) => _ResponseTile(
                    response: response,
                    relativeDate: _relativeDate(response.createdAt),
                  )),
            ],

            // ─── Messages Section ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                loc.t('reports.messagesTitle'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Messages list
            Expanded(
              child: state.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(
                          child: Text(
                            loc.t('reports.noMessagesYet'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId ==
                                ref
                                    .read(authControllerProvider)
                                    .user
                                    ?.id;
                            return _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              relativeDate: _relativeDate(msg.createdAt),
                            );
                          },
                        ),
            ),

            // ─── Message input ───
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: loc.t('reports.typeMessage'),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: state.isSendingMessage ? null : _sendMessage,
                    icon: state.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Icon(Icons.send_rounded,
                            color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await ref
        .read(reportsControllerProvider.notifier)
        .sendReportMessage(widget.report.id, text);
  }
}

// ────────────────────────────────────────────────────────────────
// Response Tile
// ────────────────────────────────────────────────────────────────

class _ResponseTile extends StatelessWidget {
  final ReportResponse response;
  final String relativeDate;

  const _ResponseTile({
    required this.response,
    required this.relativeDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.lightOcean,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppTheme.borderRadiusGeometry,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          size: 14,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        relativeDate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    response.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Message Bubble
// ────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ReportMessage message;
  final bool isMe;
  final String relativeDate;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.relativeDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.lightOcean
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(14),
            topEnd: const Radius.circular(14),
            bottomStart: isMe
                ? const Radius.circular(14)
                : Radius.zero,
            bottomEnd: isMe
                ? Radius.zero
                : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relativeDate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

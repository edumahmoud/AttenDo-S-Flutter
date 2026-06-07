import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';
import '../shared/empty_state.dart';

// ────────────────────────────────────────────────────────────
// Course Detail Page
// ────────────────────────────────────────────────────────────

class CoursePage extends ConsumerStatefulWidget {
  final String courseId;
  const CoursePage({super.key, required this.courseId});

  @override
  ConsumerState<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends ConsumerState<CoursePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabCount = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    // Load subject details when page opens
    Future.microtask(() {
      ref
          .read(subjectsControllerProvider.notifier)
          .fetchSubjectDetails(widget.courseId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    final subject = subjectsState.selectedSubject;

    if (subjectsState.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SectionErrorBoundary(
          message: loc.t('student.subjectNotFound'),
          onRetry: () => ref
              .read(subjectsControllerProvider.notifier)
              .fetchSubjectDetails(widget.courseId),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ─── Sliver Header ───
            SliverToBoxAdapter(child: _CourseHeader(subject: subject)),

            // ─── Tab Bar ───
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabController: _tabController,
                oceanColor: oceanColor,
                loc: loc,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 0: Overview
            _OverviewTab(subject: subject),
            // Tab 1: Lectures
            _LecturesTab(subjectId: subject.id),
            // Tab 2: Notes
            _ComingSoonTab(icon: LucideIcons.stickyNote, title: loc.t('student.notes')),
            // Tab 3: Files
            _FilesTab(subjectId: subject.id),
            // Tab 4: Videos
            _ComingSoonTab(icon: LucideIcons.video, title: loc.t('nav.videos')),
            // Tab 5: Exams
            _ComingSoonTab(icon: LucideIcons.fileCheck, title: loc.t('student.exams')),
            // Tab 6: Assignments
            _AssignmentsTab(subjectId: subject.id),
            // Tab 7: Chat
            _ComingSoonTab(icon: LucideIcons.messageCircle, title: loc.t('nav.chat')),
            // Tab 8: Polls
            _ComingSoonTab(icon: LucideIcons.barChart3, title: loc.t('nav.polls')),
            // Tab 9: Lessons
            _ComingSoonTab(icon: LucideIcons.bookOpen, title: loc.t('student.lessons')),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Course Header
// ────────────────────────────────────────────────────────────

class _CourseHeader extends StatelessWidget {
  final Subject subject;
  const _CourseHeader({required this.subject});

  Color get _subjectColor {
    if (subject.color != null) {
      final hex = subject.color!.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return AppColors.lightOcean;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _subjectColor.withValues(alpha: 0.08),
            _subjectColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              // Copy join code
              if (subject.code != null)
                _CopyCodeButton(code: subject.code!),
            ],
          ),
          const SizedBox(height: 8),
          // Subject name
          Text(
            subject.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Teacher info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _subjectColor.withValues(alpha: 0.15),
                child: Icon(
                  LucideIcons.user,
                  size: 16,
                  color: _subjectColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subject.teacherId ?? loc.t('student.teacher'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Description
          if (subject.description != null &&
              subject.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subject.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Color indicator bar
          const SizedBox(height: 12),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: _subjectColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Copy Code Button
// ────────────────────────────────────────────────────────────

class _CopyCodeButton extends StatelessWidget {
  final String code;
  const _CopyCodeButton({required this.code});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('student.codeCopied'))),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.copy, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              code,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Tab Bar Delegate
// ────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color oceanColor;
  final AppLocalizations loc;

  _TabBarDelegate({
    required this.tabController,
    required this.oceanColor,
    required this.loc,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oceanColor != oldDelegate.oceanColor;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: oceanColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: oceanColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
        tabs: [
          Tab(text: loc.t('student.overview')),
          Tab(text: loc.t('student.lectures')),
          Tab(text: loc.t('student.notes')),
          Tab(text: loc.t('nav.files')),
          Tab(text: loc.t('nav.videos')),
          Tab(text: loc.t('student.exams')),
          Tab(text: loc.t('nav.assignments')),
          Tab(text: loc.t('nav.chat')),
          Tab(text: loc.t('nav.polls')),
          Tab(text: loc.t('student.lessons')),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Overview Tab
// ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Subject subject;
  const _OverviewTab({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── Subject Info Card ───
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('student.subjectInfo'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(LucideIcons.user, loc.t('student.teacher'),
                    subject.teacherId ?? '—', theme),
                const SizedBox(height: 10),
                _infoRow(LucideIcons.hash, loc.t('student.subjectCode'),
                    subject.code ?? '—', theme),
                const SizedBox(height: 10),
                _infoRow(LucideIcons.calendar, loc.t('common.date'),
                    DateFormat(AppConstants.dateFormatAr).format(subject.createdAt),
                    theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ─── Recent Activity Placeholder ───
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('student.recentActivity'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                EmptyState(
                  icon: LucideIcons.activity,
                  title: loc.t('common.noData'),
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Lectures Tab
// ────────────────────────────────────────────────────────────

class _LecturesTab extends ConsumerWidget {
  final String subjectId;
  const _LecturesTab({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(studentDashboardControllerProvider);
    final loc = AppLocalizations.of(context);

    // Filter attendance sessions for this subject
    final lectures = dashboard.attendance
        .where((a) => a.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (dashboard.isLoadingAttendance) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(3, (_) => const LoadingShimmerCardBlock()),
      );
    }

    if (lectures.isEmpty) {
      return EmptyState(
        icon: LucideIcons.bookOpen,
        title: loc.t('student.noLectures'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        return _LectureCard(lecture: lecture);
      },
    );
  }
}

class _LectureCard extends StatelessWidget {
  final AttendanceSession lecture;
  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    // Check if there's an active attendance (green dot)
    final isActive = DateTime.now().difference(lecture.date).inHours < 2;

    // Find the student's attendance status
    AttendanceStatus? studentStatus;
    if (lecture.records != null && lecture.records!.isNotEmpty) {
      studentStatus = lecture.records!.first.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: () {
          // Navigate to lecture details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${lecture.date.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      _monthShort(lecture.date.month),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lecture.title ??
                                '${loc.t('student.lecture')} ${lecture.date.day}/${lecture.date.month}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF16A34A).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(lecture.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Attendance status badge
              if (studentStatus != null)
                _attendanceBadge(studentStatus, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceBadge(AttendanceStatus status, ThemeData theme) {
    Color color;
    String label;
    switch (status) {
      case AttendanceStatus.present:
        color = const Color(0xFF16A34A);
        label = '✓';
        break;
      case AttendanceStatus.late:
        color = AppColors.lightAmberAccent;
        label = '⏰';
        break;
      case AttendanceStatus.absent:
        color = const Color(0xFFDC2626);
        label = '✗';
        break;
      case AttendanceStatus.excused:
        color = const Color(0xFF7C3AED);
        label = '!';
        break;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ────────────────────────────────────────────────────────────
// Files Tab
// ────────────────────────────────────────────────────────────

class _FilesTab extends ConsumerWidget {
  final String subjectId;
  const _FilesTab({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    // In a real app, this would load from a dedicated files provider
    // For now, show a placeholder
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        EmptyState(
          icon: LucideIcons.folderOpen,
          title: loc.t('files.noFiles'),
          description: loc.t('student.noSubjectFiles'),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Assignments Tab
// ────────────────────────────────────────────────────────────

class _AssignmentsTab extends ConsumerWidget {
  final String subjectId;
  const _AssignmentsTab({required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(studentDashboardControllerProvider);
    final loc = AppLocalizations.of(context);

    // Filter assignments for this subject
    final assignments = dashboard.assignments
        .where((a) => a.subjectId == subjectId)
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    if (dashboard.isLoadingAssignments) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(3, (_) => const LoadingShimmerCardBlock()),
      );
    }

    if (assignments.isEmpty) {
      return EmptyState(
        icon: LucideIcons.clipboardList,
        title: loc.t('assignments.noAssignments'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return _AssignmentCard(assignment: assignment);
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    // Check submission status
    final submission = assignment.submissions?.isNotEmpty == true
        ? assignment.submissions!.first
        : null;
    final isSubmitted = submission?.submittedAt != null;
    final isGraded = submission?.gradedAt != null;
    final isOverdue = assignment.dueDate != null &&
        assignment.dueDate!.isBefore(DateTime.now()) &&
        !isSubmitted;

    Color statusColor;
    String statusLabel;
    if (isGraded) {
      statusColor = const Color(0xFF16A34A); // green
      statusLabel = loc.t('assignments.graded');
    } else if (isSubmitted) {
      statusColor = AppColors.lightOcean;
      statusLabel = loc.t('assignments.submitted');
    } else if (isOverdue) {
      statusColor = const Color(0xFFDC2626); // red
      statusLabel = loc.t('assignments.late');
    } else {
      statusColor = AppColors.lightAmberAccent;
      statusLabel = loc.t('assignments.pending');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: () {
          // Navigate to assignment details
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.clipboardList,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (assignment.dueDate != null)
                      Text(
                        '${loc.t('assignments.dueDate')}: ${DateFormat(AppConstants.dateFormatAr).format(assignment.dueDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Score display if graded
              if (isGraded && submission!.grade != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${submission.grade!.toStringAsFixed(0)}${assignment.maxGrade != null ? '/${assignment.maxGrade!.toStringAsFixed(0)}' : ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Coming Soon Tab (Placeholder)
// ────────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ComingSoonTab({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.ocean(brightness).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.ocean(brightness).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('student.comingSoon'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

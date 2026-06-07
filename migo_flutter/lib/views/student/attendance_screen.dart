import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../controllers/controllers.dart';
import '../../i18n/app_localizations.dart';
import '../../models/models.dart';
import '../shared/empty_state.dart';
import '../shared/loading_shimmer.dart';
import '../shared/stat_card.dart';

// ─── Attendance Screen ───

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showCalendar = false;
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch sessions for richer data on init
    Future.microtask(() {
      ref.read(attendanceControllerProvider.notifier).fetchAttendanceSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(attendanceControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => ref
              .read(attendanceControllerProvider.notifier)
              .fetchAttendanceRecords(),
          child: CustomScrollView(
            slivers: [
              // ─── Header with overall rate ───
              SliverToBoxAdapter(child: _buildOverallRate(loc, state)),

              // ─── Stat Cards Row ───
              SliverToBoxAdapter(child: _buildStatCards(loc, state)),

              // ─── Active Sessions Banner ───
              SliverToBoxAdapter(child: _buildActiveSessions(loc, state)),

              // ─── Attendance by Subject ───
              SliverToBoxAdapter(child: _buildSubjectSectionTitle(loc)),
              _buildSubjectList(loc, state),

              // ─── Calendar / History toggle ───
              SliverToBoxAdapter(child: _buildHistoryHeader(loc)),

              if (_showCalendar)
                SliverToBoxAdapter(child: _buildCalendarView(loc, state))
              else
                _buildHistoryList(loc, state),
            ],
          ),
        ),
        // ─── FAB: QR scan ───
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openQRScanner(loc),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text(loc.t('attendance.scanQR')),
        ),
      ),
    );
  }

  // ─── Overall Attendance Rate ───

  Widget _buildOverallRate(AppLocalizations loc, AttendanceState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rate = state.attendanceRate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('attendance.title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.t('attendance.rate'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: rate / 100,
                    strokeWidth: 6,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    color: rate >= 75
                        ? AppColors.lightTealAccent
                        : rate >= 50
                            ? AppColors.lightAmberAccent
                            : AppColors.lightDestructive,
                  ),
                ),
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stat Cards ───

  Widget _buildStatCards(AppLocalizations loc, AttendanceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.check_circle_outline_rounded,
              title: loc.t('attendance.present'),
              value: '${state.presentCount}',
              accentColor: AppColors.lightTealAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.access_time_rounded,
              title: loc.t('attendance.late'),
              value: '${state.lateCount}',
              accentColor: AppColors.lightAmberAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.cancel_outlined,
              title: loc.t('attendance.absent'),
              value: '${state.absentCount}',
              accentColor: AppColors.lightDestructive,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active Sessions ───

  Widget _buildActiveSessions(AppLocalizations loc, AttendanceState state) {
    // Determine active sessions (sessions from today that don't have a record yet)
    final now = DateTime.now();
    final activeSessions = state.sessions.where((s) {
      final isToday = s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;
      final studentRecords = ref.read(attendanceControllerProvider).records;
      final studentIds = studentRecords.map((r) => r.studentId).toSet();
      final hasRecord = s.records?.any((r) => studentIds.contains(r.studentId)) ?? false;
      return isToday && !hasRecord;
    }).toList();

    if (activeSessions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: AppColors.lightOcean.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusGeometry,
          side: BorderSide(color: AppColors.lightOcean.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fiber_manual_record_rounded,
                      size: 12, color: AppColors.lightOcean),
                  const SizedBox(width: 8),
                  Text(
                    loc.t('common.active'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.lightOcean,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activeSessions.map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.title ??
                                '${loc.t('attendance.title')} - ${session.subjectId}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CheckInButton(
                          sessionId: session.id,
                          loc: loc,
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openQRScanner(loc),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: Text(loc.t('attendance.scanQR')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // GPS check-in would go here
                      },
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: const Text('GPS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Attendance by Subject ───

  Widget _buildSubjectSectionTitle(AppLocalizations loc) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        loc.t('attendance.bySubject'),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSubjectList(AppLocalizations loc, AttendanceState state) {
    if (state.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
                3, (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: LoadingShimmerCardBlock())),
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: loc.t('attendance.noData'),
        ),
      );
    }

    // Group records by session -> subjectId
    final subjectMap = <String, List<AttendanceRecord>>{};
    for (final session in state.sessions) {
      final records = session.records ?? [];
      for (final r in records) {
        subjectMap.putIfAbsent(session.subjectId, () => []).add(r);
      }
    }

    if (subjectMap.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: loc.t('attendance.noData'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final subjectId = subjectMap.keys.elementAt(index);
          final records = subjectMap[subjectId]!;
          return _SubjectAttendanceCard(
            subjectId: subjectId,
            records: records,
            loc: loc,
          );
        },
        childCount: subjectMap.length,
      ),
    );
  }

  // ─── History Header with Calendar Toggle ───

  Widget _buildHistoryHeader(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              loc.t('attendance.title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
            icon: Icon(
              _showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded,
              size: 18,
            ),
            label: Text(
              _showCalendar
                  ? loc.t('common.view')
                  : loc.t('nav.calendar'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── History List ───

  Widget _buildHistoryList(AppLocalizations loc, AttendanceState state) {
    if (state.records.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: loc.t('attendance.noData'),
        ),
      );
    }

    // Map session id to session for title/subject lookup
    final sessionMap = <String, AttendanceSession>{};
    for (final s in state.sessions) {
      sessionMap[s.id] = s;
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final record = state.records[index];
          final session = sessionMap[record.sessionId];
          return _AttendanceRecordCard(
            record: record,
            session: session,
            loc: loc,
          );
        },
        childCount: state.records.length,
      ),
    );
  }

  // ─── Calendar View ───

  Widget _buildCalendarView(AppLocalizations loc, AttendanceState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Map dates to status
    final dateStatusMap = <DateTime, AttendanceStatus>{};
    for (final r in state.records) {
      final date = DateTime(
          r.createdAt.year, r.createdAt.month, r.createdAt.day);
      dateStatusMap[date] = r.status;
    }

    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sun = 0

    final daysInMonth = lastDay.day;
    final locale = loc.isRTL ? 'ar' : 'en';
    final monthLabel = '${DateFormat.MMMM(locale).format(_calendarMonth)} ${_calendarMonth.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _calendarMonth = DateTime(
                        _calendarMonth.year, _calendarMonth.month - 1)),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    monthLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _calendarMonth = DateTime(
                        _calendarMonth.year, _calendarMonth.month + 1)),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Day headers
              Row(
                children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),

              // Days grid
              Wrap(
                spacing: 0,
                runSpacing: 4,
                children: [
                  // Empty cells before first day
                  for (int i = 0; i < startWeekday; i++)
                    const SizedBox(width: 40, height: 36),
                  // Day cells
                  for (int day = 1; day <= daysInMonth; day++)
                    _CalendarDay(
                      day: day,
                      status: dateStatusMap[DateTime(
                          _calendarMonth.year, _calendarMonth.month, day)],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── QR Scanner ───

  void _openQRScanner(AppLocalizations loc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _QRScannerScreen(loc: loc),
      ),
    );
  }
}

// ─── Check-In Button ───

class _CheckInButton extends ConsumerStatefulWidget {
  final String sessionId;
  final AppLocalizations loc;

  const _CheckInButton({required this.sessionId, required this.loc});

  @override
  ConsumerState<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<_CheckInButton> {
  bool _checkedIn = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_checkedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lightTealAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 16, color: AppColors.lightTealAccent),
            const SizedBox(width: 4),
            Text(
              widget.loc.t('attendance.checkedIn'),
              style: TextStyle(
                color: AppColors.lightTealAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(attendanceControllerProvider.notifier)
                  .manualCheckIn(widget.sessionId);
              if (!mounted) return;
              setState(() {
                _loading = false;
                if (success) _checkedIn = true;
              });
              if (!success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(widget.loc.t('attendance.checkInFailed')),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(widget.loc.t('attendance.checkedIn')),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.loc.t('attendance.manualCheckIn')),
    );
  }
}

// ─── Subject Attendance Card ───

class _SubjectAttendanceCard extends StatelessWidget {
  final String subjectId;
  final List<AttendanceRecord> records;
  final AppLocalizations loc;

  const _SubjectAttendanceCard({
    required this.subjectId,
    required this.records,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final presentCount =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final absentCount =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final total = records.length;
    final rate = total > 0 ? ((presentCount + lateCount) / total) * 100 : 0.0;

    // Trend: compare last 3 records vs previous 3
    final trend = _computeTrend();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _subjectColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subjectId,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildTrendIcon(trend),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  minHeight: 6,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  color: rate >= 75
                      ? AppColors.lightTealAccent
                      : rate >= 50
                          ? AppColors.lightAmberAccent
                          : AppColors.lightDestructive,
                ),
              ),
              const SizedBox(height: 10),

              // Counts row
              Row(
                children: [
                  _buildCountChip(
                    Icons.check_circle_outline_rounded,
                    loc.t('attendance.present'),
                    presentCount,
                    AppColors.lightTealAccent,
                  ),
                  const SizedBox(width: 12),
                  _buildCountChip(
                    Icons.access_time_rounded,
                    loc.t('attendance.late'),
                    lateCount,
                    AppColors.lightAmberAccent,
                  ),
                  const SizedBox(width: 12),
                  _buildCountChip(
                    Icons.cancel_outlined,
                    loc.t('attendance.absent'),
                    absentCount,
                    AppColors.lightDestructive,
                  ),
                  const Spacer(),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountChip(IconData icon, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIcon(double trend) {
    if (trend > 0) {
      return Icon(Icons.trending_up_rounded,
          size: 18, color: AppColors.lightTealAccent);
    } else if (trend < 0) {
      return Icon(Icons.trending_down_rounded,
          size: 18, color: AppColors.lightDestructive);
    }
    return Icon(Icons.trending_flat_rounded,
        size: 18, color: AppColors.lightAmberAccent);
  }

  double _computeTrend() {
    if (records.length < 4) return 0;
    final recent = records.take(3);
    final older = records.skip(3).take(3);
    double recentRate = 0;
    double olderRate = 0;
    int recentCount = 0;
    int olderCount = 0;
    for (final r in recent) {
      if (r.status == AttendanceStatus.present ||
          r.status == AttendanceStatus.late) {
        recentCount++;
      }
    }
    for (final r in older) {
      if (r.status == AttendanceStatus.present ||
          r.status == AttendanceStatus.late) {
        olderCount++;
      }
    }
    recentRate = recentCount / 3;
    olderRate = olderCount / 3;
    return recentRate - olderRate;
  }

  Color _subjectColor() {
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
}

// ─── Attendance Record Card ───

class _AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final AttendanceSession? session;
  final AppLocalizations loc;

  const _AttendanceRecordCard({
    required this.record,
    this.session,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = loc.isRTL ? 'ar' : 'en';

    final (statusLabel, statusColor) = _statusInfo();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.title ?? record.sessionId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd(locale)
                          .add_jm()
                          .format(record.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusInfo() {
    return switch (record.status) {
      AttendanceStatus.present =>
          (loc.t('attendance.present'), AppColors.lightTealAccent),
      AttendanceStatus.late =>
          (loc.t('attendance.late'), AppColors.lightAmberAccent),
      AttendanceStatus.absent =>
          (loc.t('attendance.absent'), AppColors.lightDestructive),
      AttendanceStatus.excused =>
          (loc.t('attendance.excused'), AppColors.lightOcean),
    };
  }
}

// ─── Calendar Day Cell ───

class _CalendarDay extends StatelessWidget {
  final int day;
  final AttendanceStatus? status;

  const _CalendarDay({required this.day, this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AttendanceStatus.present => AppColors.lightTealAccent,
      AttendanceStatus.late => AppColors.lightAmberAccent,
      AttendanceStatus.absent => AppColors.lightDestructive,
      AttendanceStatus.excused => AppColors.lightOcean,
      null => Colors.transparent,
    };

    return SizedBox(
      width: 40,
      height: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          if (status != null)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── QR Scanner Screen ───

class _QRScannerScreen extends ConsumerStatefulWidget {
  final AppLocalizations loc;
  const _QRScannerScreen({required this.loc});

  @override
  ConsumerState<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<_QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.loc.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.loc.t('attendance.scanQR')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: _scannerController,
              onDetect: _onQRDetected,
            ),

            // Scan overlay
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Instructions
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                widget.loc.t('attendance.scanQR'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Processing indicator
            if (_processing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _processing = true);
    _handleQRResult(barcode.rawValue!);
  }

  Future<void> _handleQRResult(String qrData) async {
    final success = await ref
        .read(attendanceControllerProvider.notifier)
        .scanQRCode(qrData);

    if (mounted) {
      setState(() => _processing = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.loc.t('attendance.checkedIn')),
            backgroundColor: AppColors.lightTealAccent,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.loc.t('attendance.checkInFailed')),
            backgroundColor: AppColors.lightDestructive,
          ),
        );
      }
    }
  }
}

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

// ─── View Mode ───

enum CalendarViewMode { month, week, agenda }

// ─── Calendar Screen ───

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.agenda;
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(calendarControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => ref
              .read(calendarControllerProvider.notifier)
              .fetchCalendarEvents(state.selectedMonth, state.selectedYear),
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(child: _buildHeader(loc, state)),

              // ─── View Toggle ───
              SliverToBoxAdapter(child: _buildViewToggle(loc)),

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
                        .read(calendarControllerProvider.notifier)
                        .fetchCalendarEvents(
                            state.selectedMonth, state.selectedYear),
                  ),
                )
              else ...[
                switch (_viewMode) {
                  CalendarViewMode.month => _buildMonthView(loc, state),
                  CalendarViewMode.week => _buildWeekView(loc, state),
                  CalendarViewMode.agenda => _buildAgendaView(loc, state),
                },
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, CalendarState state) {
    final theme = Theme.of(context);
    final monthYear = DateFormat.yMMMM(loc.isRTL ? 'ar' : 'en').format(
      DateTime(state.selectedYear, state.selectedMonth),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          // Previous month
          IconButton(
            onPressed: () => ref
                .read(calendarControllerProvider.notifier)
                .previousMonth(),
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          // Month/Year
          Expanded(
            child: Column(
              children: [
                Text(
                  monthYear,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Next month
          IconButton(
            onPressed: () => ref
                .read(calendarControllerProvider.notifier)
                .nextMonth(),
            icon: const Icon(Icons.chevron_right_rounded),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          // Today button
          TextButton(
            onPressed: () {
              ref.read(calendarControllerProvider.notifier).goToToday();
              setState(() => _selectedDay = DateTime.now());
            },
            child: Text(loc.t('calendar.today')),
          ),
        ],
      ),
    );
  }

  // ─── View Toggle ───

  Widget _buildViewToggle(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final views = [
      (CalendarViewMode.month, Icons.calendar_view_month_rounded,
          loc.t('calendar.month')),
      (CalendarViewMode.week, Icons.view_week_rounded,
          loc.t('calendar.week')),
      (CalendarViewMode.agenda, Icons.view_agenda_rounded,
          loc.t('calendar.agenda')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: views.map((v) {
          final (mode, icon, label) = v;
          final isSelected = _viewMode == mode;

          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              ),
              onSelected: (_) => setState(() => _viewMode = mode),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusGeometry,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Month View ───

  Widget _buildMonthView(AppLocalizations loc, CalendarState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final firstOfMonth =
        DateTime(state.selectedYear, state.selectedMonth, 1);
    final startDay = firstOfMonth.weekday % 7; // 0=Sun
    final daysInMonth =
        DateTime(state.selectedYear, state.selectedMonth + 1, 0).day;

    // Day headers
    final dayLabels = [
      loc.t('time.sunday'),
      loc.t('time.monday'),
      loc.t('time.tuesday'),
      loc.t('time.wednesday'),
      loc.t('time.thursday'),
      loc.t('time.friday'),
      loc.t('time.saturday'),
    ];
    final shortDayLabels =
        dayLabels.map((d) => d.length > 2 ? d.substring(0, 2) : d).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            // Day headers
            Row(
              children: shortDayLabels
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
            // Calendar grid
            ...List.generate(
              ((startDay + daysInMonth) / 7).ceil(),
              (weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final cellIndex = weekIndex * 7 + dayIndex;
                    final dayNumber = cellIndex - startDay + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    final day = DateTime(
                        state.selectedYear, state.selectedMonth, dayNumber);
                    final isToday = day.year == now.year &&
                        day.month == now.month &&
                        day.day == now.day;
                    final isSelected = day.year == _selectedDay.year &&
                        day.month == _selectedDay.month &&
                        day.day == _selectedDay.day;
                    final events = state.eventsForDay(day);
                    final hasEvents = events.isNotEmpty;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedDay = day);
                          if (events.isNotEmpty) {
                            _showDayDetail(loc, day, events);
                          }
                        },
                        child: Container(
                          height: 72,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.08)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: AppColors
                                        .ocean(theme.brightness),
                                    width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Date number
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.ocean(theme.brightness)
                                      : null,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$dayNumber',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: isToday
                                          ? AppColors.oceanForeground(
                                              theme.brightness)
                                          : colorScheme.onSurface,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Event dots (up to 3)
                              if (hasEvents)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: events
                                      .take(3)
                                      .map((e) => Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets
                                                .symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color:
                                                  _eventTypeColor(e.type),
                                              shape: BoxShape.circle,
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Week View ───

  Widget _buildWeekView(AppLocalizations loc, CalendarState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    // Get the start of the week containing _selectedDay
    final startOfWeek = _selectedDay
        .subtract(Duration(days: _selectedDay.weekday % 7));

    final hours = List.generate(12, (i) => i + 7); // 7 AM to 6 PM
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              children: days.map((day) {
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(loc.isRTL ? 'ar' : 'en').format(day),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.ocean(theme.brightness)
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isToday
                                  ? AppColors.oceanForeground(
                                      theme.brightness)
                                  : colorScheme.onSurface,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Time grid
          ...hours.map((hour) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time label
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${hour > 12 ? hour - 12 : hour}${hour >= 12 ? 'PM' : 'AM'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Day cells
                  ...days.map((day) {
                    final dayEvents = state.eventsForDay(day).where((e) {
                      return e.startDate.hour == hour;
                    }).toList();

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedDay = day);
                          if (state.eventsForDay(day).isNotEmpty) {
                            _showDayDetail(
                                loc, day, state.eventsForDay(day));
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: colorScheme.outlineVariant,
                                  width: 0.5),
                              right: BorderSide(
                                  color: colorScheme.outlineVariant,
                                  width: 0.5),
                            ),
                          ),
                          child: Column(
                            children: dayEvents.take(2).map((e) {
                              return Container(
                                height: 18,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 1),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _eventTypeColor(e.type)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.title,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _eventTypeColor(e.type),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Agenda View ───

  Widget _buildAgendaView(AppLocalizations loc, CalendarState state) {
    final events = state.eventsForSelectedMonth;

    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.event_busy_rounded,
          title: loc.t('calendar.noEvents'),
        ),
      );
    }

    // Group by day
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final day = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      grouped.putIfAbsent(day, () => []).add(event);
    }

    final sortedDays = grouped.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final day = sortedDays[index];
          final dayEvents = grouped[day]!;
          final now = DateTime.now();
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isTomorrow =
              day.difference(DateTime(now.year, now.month, now.day)).inDays ==
                  1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      isToday
                          ? loc.t('calendar.today')
                          : isTomorrow
                              ? loc.t('time.tomorrow')
                              : DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en')
                                  .format(day),
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? AppColors.ocean(
                                        Theme.of(context).brightness)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.ocean(Theme.of(context).brightness)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${dayEvents.length}',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.ocean(
                                      Theme.of(context).brightness),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              // Event cards
              ...dayEvents.map((event) => _buildAgendaEventCard(loc, event)),
            ],
          );
        },
        childCount: sortedDays.length,
      ),
    );
  }

  // ─── Agenda Event Card ───

  Widget _buildAgendaEventCard(AppLocalizations loc, CalendarEvent event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _eventTypeColor(event.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () => _showEventDetail(loc, event),
          borderRadius: AppTheme.borderRadiusGeometry,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: typeColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _eventTypeIcon(event.type),
                    size: 18,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Title & time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            event.isAllDay == true
                                ? loc.t('calendar.allDay')
                                : DateFormat.jm(loc.isRTL ? 'ar' : 'en')
                                    .format(event.startDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (event.location != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                event.location!,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Subject badge
                if (event.subjectId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _subjectColor(event.subjectId!)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_rounded,
                            size: 12,
                            color: _subjectColor(event.subjectId!)),
                        const SizedBox(width: 2),
                        Text(
                          _subjectName(event.subjectId!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _subjectColor(event.subjectId!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Day Detail Sheet ───

  void _showDayDetail(
      AppLocalizations loc, DateTime day, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en').format(day),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child:
                            _buildAgendaEventCard(loc, events[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Event Detail Sheet ───

  void _showEventDetail(AppLocalizations loc, CalendarEvent event) {
    final theme = Theme.of(context);
    final typeColor = _eventTypeColor(event.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type indicator
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _eventTypeIcon(event.type),
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date & time
                  _buildDetailRow(
                    Icons.event_rounded,
                    DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en')
                        .format(event.startDate),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.schedule_rounded,
                    event.isAllDay == true
                        ? loc.t('calendar.allDay')
                        : DateFormat.jm(loc.isRTL ? 'ar' : 'en')
                            .format(event.startDate),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        Icons.location_on_rounded, event.location!),
                  ],
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      event.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───

  Color _eventTypeColor(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.lecture => AppColors.lightOcean,
      CalendarEventType.quiz => const Color(0xFF8B5CF6), // purple
      CalendarEventType.assignment => AppColors.lightAmberAccent,
      CalendarEventType.exam => AppColors.lightDestructive,
      CalendarEventType.meeting => const Color(0xFF6366F1), // indigo
      CalendarEventType.event => AppColors.lightTealAccent,
      CalendarEventType.holiday => const Color(0xFF22C55E), // green
      CalendarEventType.other => AppColors.lightMutedForeground,
    };
  }

  IconData _eventTypeIcon(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.lecture => Icons.menu_book_rounded,
      CalendarEventType.quiz => Icons.help_outline_rounded,
      CalendarEventType.assignment => Icons.assignment_rounded,
      CalendarEventType.exam => Icons.quiz_rounded,
      CalendarEventType.meeting => Icons.groups_rounded,
      CalendarEventType.event => Icons.event_rounded,
      CalendarEventType.holiday => Icons.celebration_rounded,
      CalendarEventType.other => Icons.circle_rounded,
    };
  }

  Color _subjectColor(String subjectId) {
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

  String _subjectName(String subjectId) {
    try {
      final subjectsState = ref.read(subjectsControllerProvider);
      final subject =
          subjectsState.subjects.where((s) => s.id == subjectId).firstOrNull;
      return subject?.name ?? subjectId;
    } catch (_) {
      return subjectId;
    }
  }
}

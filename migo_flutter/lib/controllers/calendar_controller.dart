import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Calendar State ───

class CalendarState {
  final List<CalendarEvent> events;
  final int selectedMonth;
  final int selectedYear;
  final bool isLoading;
  final String? error;

  const CalendarState({
    this.events = const [],
    this.selectedMonth = 1,
    this.selectedYear = 2025,
    this.isLoading = false,
    this.error,
  });

  /// Events filtered for the selected month/year.
  List<CalendarEvent> get eventsForSelectedMonth => events.where((e) {
        final startMonth = e.startDate.month;
        final startYear = e.startDate.year;
        // Include if start date is in the selected month
        if (startYear == selectedYear && startMonth == selectedMonth) {
          return true;
        }
        // Include multi-day events that span into the selected month
        if (e.endDate != null) {
          final endMonth = e.endDate!.month;
          final endYear = e.endDate!.year;
          if (endYear == selectedYear && endMonth == selectedMonth) {
            return true;
          }
        }
        return false;
      }).toList();

  /// Events for a specific day.
  List<CalendarEvent> eventsForDay(DateTime day) {
    return events.where((e) {
      final startDay = DateTime(
        e.startDate.year,
        e.startDate.month,
        e.startDate.day,
      );
      final checkDay = DateTime(day.year, day.month, day.day);
      if (startDay == checkDay) return true;
      if (e.endDate != null) {
        final endDay = DateTime(
          e.endDate!.year,
          e.endDate!.month,
          e.endDate!.day,
        );
        return checkDay.isAfter(startDay) && !checkDay.isAfter(endDay);
      }
      return false;
    }).toList();
  }

  /// Events of a specific type.
  List<CalendarEvent> eventsOfType(CalendarEventType type) =>
      events.where((e) => e.type == type).toList();

  CalendarState copyWith({
    List<CalendarEvent>? events,
    int? selectedMonth,
    int? selectedYear,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CalendarState(
      events: events ?? this.events,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Calendar Controller ───

class CalendarController extends StateNotifier<CalendarState> {
  final SupabaseService _supabaseService;

  CalendarController(this._supabaseService)
      : super(CalendarState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    fetchCalendarEvents(state.selectedMonth, state.selectedYear);
  }

  Future<void> fetchCalendarEvents(int month, int year) async {
    state = state.copyWith(
      isLoading: true,
      selectedMonth: month,
      selectedYear: year,
      clearError: true,
    );
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Calculate date range for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // No 'calendar_events' table exists — aggregate from assignments, quizzes, todos
      final aggregatedEvents = await _aggregateEvents(
        month,
        year,
        userId,
      );

      state = state.copyWith(
        events: aggregatedEvents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<List<CalendarEvent>> _aggregateEvents(
    int month,
    int year,
    String userId,
  ) async {
    final aggregated = <CalendarEvent>[];
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    try {
      // Aggregate assignments with due dates
      final assignmentsData = await _supabaseService.client
          .from('assignments')
          .select('id, title, due_date, subject_id')
          .gte('due_date', startDate.toIso8601String())
          .lte('due_date', endDate.toIso8601String());

      for (final row in assignmentsData) {
        if (row['due_date'] != null) {
          aggregated.add(CalendarEvent(
            id: 'assignment_${row['id']}',
            userId: userId,
            title: row['title'] ?? 'Assignment',
            type: CalendarEventType.assignment,
            startDate: DateTime.parse(row['due_date'] as String),
            subjectId: row['subject_id'] as String?,
            referenceId: row['id'] as String,
            referenceType: 'assignment',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    } catch (_) {
      // Silently ignore aggregation errors for partial results
    }

    try {
      // Aggregate todos with due dates
      final todosData = await _supabaseService.client
          .from('user_todos')
          .select('id, title, due_date')
          .eq('user_id', userId)
          .gte('due_date', startDate.toIso8601String())
          .lte('due_date', endDate.toIso8601String());

      for (final row in todosData) {
        if (row['due_date'] != null) {
          aggregated.add(CalendarEvent(
            id: 'todo_${row['id']}',
            userId: userId,
            title: row['title'] ?? 'Todo',
            type: CalendarEventType.other,
            startDate: DateTime.parse(row['due_date'] as String),
            referenceId: row['id'] as String,
            referenceType: 'todo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    } catch (_) {
      // Silently ignore
    }

    return aggregated;
  }

  void selectMonth(int month, int year) {
    fetchCalendarEvents(month, year);
  }

  void goToToday() {
    final now = DateTime.now();
    fetchCalendarEvents(now.month, now.year);
  }

  void previousMonth() {
    final date = DateTime(state.selectedYear, state.selectedMonth - 1);
    fetchCalendarEvents(date.month, date.year);
  }

  void nextMonth() {
    final date = DateTime(state.selectedYear, state.selectedMonth + 1);
    fetchCalendarEvents(date.month, date.year);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load calendar events. Please try again.';
  }
}

// ─── Provider ───

final calendarControllerProvider =
    StateNotifierProvider<CalendarController, CalendarState>((ref) {
  return CalendarController(ref.watch(supabaseServiceProvider));
});

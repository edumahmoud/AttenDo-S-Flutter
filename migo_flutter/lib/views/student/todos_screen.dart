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

// ─── Enums ───

enum TodoFilter { all, pending, completed, overdue }

enum TodoSort { dueDate, priority, category }

// ─── Todos Screen ───

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  TodoFilter _filter = TodoFilter.all;
  TodoSort _sort = TodoSort.dueDate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(todosControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTodoDialog(loc),
          icon: const Icon(Icons.add_rounded),
          label: Text(loc.t('todos.addTodo')),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(todosControllerProvider.notifier).fetchTodos(),
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
                        .read(todosControllerProvider.notifier)
                        .fetchTodos(),
                  ),
                )
              else if (state.todos.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.celebration_rounded,
                    title: loc.t('todos.noTodos'),
                    description: loc.t('todos.allCompleted'),
                  ),
                )
              else
                _buildGroupedTodos(loc, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, TodosState state) {
    final theme = Theme.of(context);
    final pendingCount = state.pendingTodos.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  loc.t('todos.myTasks'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ocean(theme.brightness)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.ocean(theme.brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildSortButton(loc),
        ],
      ),
    );
  }

  Widget _buildSortButton(AppLocalizations loc) {
    final theme = Theme.of(context);

    return PopupMenuButton<TodoSort>(
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
          value: TodoSort.dueDate,
          child: Row(
            children: [
              Icon(
                _sort == TodoSort.dueDate
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(loc.t('todos.sortByDate')),
            ],
          ),
        ),
        PopupMenuItem(
          value: TodoSort.priority,
          child: Row(
            children: [
              Icon(
                _sort == TodoSort.priority
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(loc.t('todos.sortByPriority')),
            ],
          ),
        ),
        PopupMenuItem(
          value: TodoSort.category,
          child: Row(
            children: [
              Icon(
                _sort == TodoSort.category
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(loc.t('todos.sortByCategory')),
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
      (TodoFilter.all, loc.t('todos.all')),
      (TodoFilter.pending, loc.t('todos.pending')),
      (TodoFilter.completed, loc.t('todos.completed')),
      (TodoFilter.overdue, loc.t('todos.overdue')),
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

  // ─── Filtering & Grouping ───

  List<UserTodo> _filteredTodos(TodosState state) {
    var list = List<UserTodo>.from(state.todos);

    switch (_filter) {
      case TodoFilter.all:
        break;
      case TodoFilter.pending:
        list = state.pendingTodos;
        break;
      case TodoFilter.completed:
        list = state.completedTodos;
        break;
      case TodoFilter.overdue:
        list = state.overdueTodos;
        break;
    }

    // Sort
    switch (_sort) {
      case TodoSort.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TodoSort.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case TodoSort.category:
        list.sort((a, b) => a.category.name.compareTo(b.category.name));
    }

    return list;
  }

  /// Group todos by time period for display.
  Map<String, List<UserTodo>> _groupTodos(List<UserTodo> todos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final groups = <String, List<UserTodo>>{
      'overdue': [],
      'today': [],
      'tomorrow': [],
      'thisWeek': [],
      'later': [],
    };

    for (final todo in todos) {
      if (todo.isCompleted) {
        groups['later']!.add(todo);
        continue;
      }
      if (todo.dueDate == null) {
        groups['later']!.add(todo);
        continue;
      }
      final dueDay = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      if (dueDay.isBefore(today)) {
        groups['overdue']!.add(todo);
      } else if (dueDay == today) {
        groups['today']!.add(todo);
      } else if (dueDay == tomorrow) {
        groups['tomorrow']!.add(todo);
      } else if (dueDay.isBefore(weekEnd)) {
        groups['thisWeek']!.add(todo);
      } else {
        groups['later']!.add(todo);
      }
    }

    // Remove empty groups
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  // ─── Grouped List ───

  Widget _buildGroupedTodos(AppLocalizations loc, TodosState state) {
    final filtered = _filteredTodos(state);

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: _filter == TodoFilter.completed
              ? Icons.celebration_rounded
              : Icons.task_alt_rounded,
          title: loc.t('todos.noTodos'),
          description: _filter == TodoFilter.completed
              ? null
              : loc.t('todos.allCompleted'),
        ),
      );
    }

    final groups = _groupTodos(filtered);
    final groupLabels = <String, String>{
      'overdue': loc.t('todos.overdue'),
      'today': loc.t('todos.today'),
      'tomorrow': loc.t('todos.tomorrow'),
      'thisWeek': loc.t('todos.thisWeek'),
      'later': loc.t('todos.later'),
    };

    final slivers = <Widget>[];
    for (final entry in groups.entries) {
      final groupKey = entry.key;
      final groupTodos = entry.value;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                if (groupKey == 'overdue')
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.lightDestructive),
                if (groupKey == 'overdue') const SizedBox(width: 6),
                Text(
                  groupLabels[groupKey] ?? groupKey,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: groupKey == 'overdue'
                            ? AppColors.lightDestructive
                            : Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${groupTodos.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTodoCard(loc, groupTodos[index]),
            childCount: groupTodos.length,
          ),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  // ─── Todo Card ───

  Widget _buildTodoCard(AppLocalizations loc, UserTodo todo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Track expanded state for potential future use
    final isOverdue = !todo.isCompleted &&
        todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now());
    final isDueToday = todo.dueDate != null &&
        !_isOverdue(todo) &&
        _isSameDay(todo.dueDate!, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd ||
              direction == DismissDirection.endToStart) {
            // Determine if it's the complete or delete action based on direction
            // In RTL, startToEnd is left swipe, endToStart is right swipe
            final isRtl = loc.isRTL;
            final isCompleteAction =
                (direction == DismissDirection.endToStart && !isRtl) ||
                    (direction == DismissDirection.startToEnd && isRtl);

            if (isCompleteAction) {
              await ref
                  .read(todosControllerProvider.notifier)
                  .toggleTodo(todo.id);
              return false; // Don't dismiss, just toggle
            } else {
              return await _confirmDelete(loc, todo);
            }
          }
          return false;
        },
        background: Container(
          alignment: loc.isRTL ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.lightDestructive.withValues(alpha: 0.1),
            borderRadius: AppTheme.borderRadiusGeometry,
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: AppColors.lightDestructive),
        ),
        secondaryBackground: Container(
          alignment: loc.isRTL ? Alignment.centerLeft : Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.lightTealAccent.withValues(alpha: 0.1),
            borderRadius: AppTheme.borderRadiusGeometry,
          ),
          child:
              Icon(Icons.check_circle_outline, color: AppColors.lightTealAccent),
        ),
        child: Card(
          child: InkWell(
            onTap: () => _showEditTodoDialog(loc, todo),
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
                      // Checkbox with animation
                      AnimatedScale(
                        scale: todo.isCompleted ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Checkbox(
                          value: todo.isCompleted,
                          onChanged: (_) => ref
                              .read(todosControllerProvider.notifier)
                              .toggleTodo(todo.id),
                          activeColor: AppColors.lightTealAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority indicator
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _priorityColor(todo.priority),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: todo.isCompleted
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (todo.description != null &&
                                todo.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                todo.description!,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Source badge
                      if (todo.source != TodoSource.manual)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildSourceBadge(loc, todo),
                        ),
                    ],
                  ),

                  // ─── Badges Row ───
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Due date badge
                      if (todo.dueDate != null)
                        _buildDueDateBadge(loc, todo, isOverdue, isDueToday),
                      // Priority badge
                      _buildPriorityBadge(loc, todo),
                      // Category badge
                      _buildCategoryBadge(loc, todo),
                      // Subject badge
                      if (todo.subjectId != null)
                        _buildSubjectBadge(todo),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isOverdue(UserTodo todo) {
    return !todo.isCompleted &&
        todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ─── Badge Builders ───

  Widget _buildDueDateBadge(
      AppLocalizations loc, UserTodo todo, bool isOverdue, bool isDueToday) {
    final theme = Theme.of(context);
    final color = isOverdue
        ? AppColors.lightDestructive
        : isDueToday
            ? AppColors.lightAmberAccent
            : theme.colorScheme.onSurfaceVariant;
    final bgColor = isOverdue
        ? AppColors.lightDestructive.withValues(alpha: 0.1)
        : isDueToday
            ? AppColors.lightAmberAccent.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            _formatDueDate(todo.dueDate!, loc),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(AppLocalizations loc, UserTodo todo) {
    final theme = Theme.of(context);
    final color = _priorityColor(todo.priority);
    final label = switch (todo.priority) {
      TodoPriority.urgent => loc.t('todos.urgent'),
      TodoPriority.high => loc.t('todos.high'),
      TodoPriority.medium => loc.t('todos.medium'),
      TodoPriority.low => loc.t('todos.low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(AppLocalizations loc, UserTodo todo) {
    final theme = Theme.of(context);
    final (icon, label) = switch (todo.category) {
      TodoCategory.study => (Icons.school_rounded, loc.t('todos.study')),
      TodoCategory.assignment =>
        (Icons.assignment_rounded, loc.t('todos.assignment')),
      TodoCategory.exam => (Icons.quiz_rounded, loc.t('todos.exam')),
      TodoCategory.personal =>
        (Icons.person_rounded, loc.t('todos.personal')),
      TodoCategory.project =>
        (Icons.folder_special_rounded, loc.t('todos.project')),
      TodoCategory.other => (Icons.more_horiz_rounded, loc.t('todos.other')),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(AppLocalizations loc, UserTodo todo) {
    final icon = switch (todo.source) {
      TodoSource.assignment => Icons.assignment_rounded,
      TodoSource.quiz => Icons.quiz_rounded,
      TodoSource.system => Icons.auto_fix_high_rounded,
      TodoSource.manual => Icons.edit_rounded,
    };

    return Tooltip(
      message: loc.t('todos.autoGenerated'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.lightOcean.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.lightOcean),
      ),
    );
  }

  Widget _buildSubjectBadge(UserTodo todo) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _subjectColor(todo.subjectId!).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_rounded,
              size: 12, color: _subjectColor(todo.subjectId!)),
          const SizedBox(width: 3),
          Text(
            _subjectName(todo.subjectId!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _subjectColor(todo.subjectId!),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add Todo Dialog ───

  void _showAddTodoDialog(AppLocalizations loc) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;
    TodoPriority priority = TodoPriority.medium;
    TodoCategory category = TodoCategory.other;
    String? subjectId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(todosControllerProvider);
            final subjectsState = ref.watch(subjectsControllerProvider);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(loc.t('todos.addTodo')),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            TextFormField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.todoTitle'),
                                prefixIcon: const Icon(Icons.title_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? loc.t('todos.titleRequired')
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Description
                            TextFormField(
                              controller: descController,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.todoDescription'),
                                prefixIcon:
                                    const Icon(Icons.description_rounded),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

                            // Due Date
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() => dueDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: loc.t('todos.dueDate'),
                                  prefixIcon:
                                      const Icon(Icons.event_rounded),
                                ),
                                child: Text(
                                  dueDate != null
                                      ? DateFormat.yMMMd(
                                              loc.isRTL ? 'ar' : 'en')
                                          .format(dueDate!)
                                      : '--',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Priority
                            DropdownButtonFormField<TodoPriority>(
                              initialValue: priority,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.priority'),
                                prefixIcon:
                                    const Icon(Icons.flag_rounded),
                              ),
                              items: TodoPriority.values.map((p) {
                                final label = switch (p) {
                                  TodoPriority.urgent =>
                                    loc.t('todos.urgent'),
                                  TodoPriority.high =>
                                    loc.t('todos.high'),
                                  TodoPriority.medium =>
                                    loc.t('todos.medium'),
                                  TodoPriority.low =>
                                    loc.t('todos.low'),
                                };
                                return DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _priorityColor(p),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => priority = v);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Category
                            DropdownButtonFormField<TodoCategory>(
                              initialValue: category,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.other'),
                                prefixIcon:
                                    const Icon(Icons.category_rounded),
                              ),
                              items: TodoCategory.values.map((c) {
                                final label = switch (c) {
                                  TodoCategory.study =>
                                    loc.t('todos.study'),
                                  TodoCategory.assignment =>
                                    loc.t('todos.assignment'),
                                  TodoCategory.exam =>
                                    loc.t('todos.exam'),
                                  TodoCategory.personal =>
                                    loc.t('todos.personal'),
                                  TodoCategory.project =>
                                    loc.t('todos.project'),
                                  TodoCategory.other =>
                                    loc.t('todos.other'),
                                };
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => category = v);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Subject (optional)
                            DropdownButtonFormField<String?> (
                              initialValue: subjectId,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.selectSubject'),
                                prefixIcon:
                                    const Icon(Icons.book_rounded),
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(loc.t('todos.other')),
                                ),
                                ...subjectsState.subjects.map((s) {
                                  return DropdownMenuItem<String?>(
                                    value: s.id,
                                    child: Text(s.name),
                                  );
                                }),
                              ],
                              onChanged: (v) {
                                setDialogState(() => subjectId = v);
                              },
                            ),
                          ],
                        ),
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
                              if (!formKey.currentState!.validate()) return;
                              final success = await ref
                                  .read(todosControllerProvider.notifier)
                                  .createTodo(
                                    title: titleController.text.trim(),
                                    description:
                                        descController.text.trim().isEmpty
                                            ? null
                                            : descController.text.trim(),
                                    dueDate: dueDate,
                                    priority: priority,
                                    category: category,
                                  );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                if (success) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          loc.t('todos.createdSuccess')),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          loc.t('todos.createFailed')),
                                    ),
                                  );
                                }
                              }
                            },
                      child: state.isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Text(loc.t('todos.addTodo')),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Edit Todo Dialog ───

  void _showEditTodoDialog(AppLocalizations loc, UserTodo todo) {
    final titleController = TextEditingController(text: todo.title);
    final descController =
        TextEditingController(text: todo.description ?? '');
    DateTime? dueDate = todo.dueDate;
    TodoPriority priority = todo.priority;
    TodoCategory category = todo.category;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(loc.t('todos.editTodo')),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.todoTitle'),
                                prefixIcon: const Icon(Icons.title_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? loc.t('todos.titleRequired')
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descController,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.todoDescription'),
                                prefixIcon:
                                    const Icon(Icons.description_rounded),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() => dueDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: loc.t('todos.dueDate'),
                                  prefixIcon:
                                      const Icon(Icons.event_rounded),
                                ),
                                child: Text(
                                  dueDate != null
                                      ? DateFormat.yMMMd(
                                              loc.isRTL ? 'ar' : 'en')
                                          .format(dueDate!)
                                      : '--',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TodoPriority>(
                              initialValue: priority,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.priority'),
                                prefixIcon:
                                    const Icon(Icons.flag_rounded),
                              ),
                              items: TodoPriority.values.map((p) {
                                final label = switch (p) {
                                  TodoPriority.urgent =>
                                    loc.t('todos.urgent'),
                                  TodoPriority.high =>
                                    loc.t('todos.high'),
                                  TodoPriority.medium =>
                                    loc.t('todos.medium'),
                                  TodoPriority.low =>
                                    loc.t('todos.low'),
                                };
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => priority = v);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TodoCategory>(
                              initialValue: category,
                              decoration: InputDecoration(
                                labelText: loc.t('todos.other'),
                                prefixIcon:
                                    const Icon(Icons.category_rounded),
                              ),
                              items: TodoCategory.values.map((c) {
                                final label = switch (c) {
                                  TodoCategory.study =>
                                    loc.t('todos.study'),
                                  TodoCategory.assignment =>
                                    loc.t('todos.assignment'),
                                  TodoCategory.exam =>
                                    loc.t('todos.exam'),
                                  TodoCategory.personal =>
                                    loc.t('todos.personal'),
                                  TodoCategory.project =>
                                    loc.t('todos.project'),
                                  TodoCategory.other =>
                                    loc.t('todos.other'),
                                };
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => category = v);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            // Mark complete / Delete
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: !todo.isCompleted
                                        ? () async {
                                            await ref
                                                .read(
                                                    todosControllerProvider
                                                        .notifier)
                                                .toggleTodo(todo.id);
                                            if (ctx.mounted) {
                                              Navigator.of(ctx).pop();
                                            }
                                          }
                                        : null,
                                    icon: Icon(
                                      todo.isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label:
                                        Text(loc.t('todos.markComplete')),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirmed =
                                          await _confirmDelete(loc, todo);
                                      if (confirmed && ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18),
                                    label: Text(loc.commonDelete),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          AppColors.lightDestructive,
                                      side: const BorderSide(
                                          color: AppColors.lightDestructive),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(loc.commonCancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(todosControllerProvider.notifier)
                            .updateTodo(todo.id, {
                          'title': titleController.text.trim(),
                          'description': descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          'dueDate': dueDate?.toIso8601String(),
                          'priority': priority.name,
                          'category': category.name,
                        });
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(loc.t('todos.updatedSuccess'))),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(loc.t('todos.updateFailed'))),
                            );
                          }
                        }
                      },
                      child: Text(loc.commonSave),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Delete Confirmation ───

  Future<bool> _confirmDelete(AppLocalizations loc, UserTodo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.commonDelete),
        content: Text(loc.t('todos.deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightDestructive,
              foregroundColor: AppColors.lightDestructiveForeground,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(todosControllerProvider.notifier)
          .deleteTodo(todo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? loc.t('todos.deletedSuccess')
                : loc.t('todos.deleteFailed')),
          ),
        );
      }
      return success;
    }
    return false;
  }

  // ─── Helpers ───

  Color _priorityColor(TodoPriority priority) {
    return switch (priority) {
      TodoPriority.urgent => AppColors.lightDestructive,
      TodoPriority.high => AppColors.lightAmberAccent,
      TodoPriority.medium => AppColors.lightOcean,
      TodoPriority.low => AppColors.lightMutedForeground,
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

  String _formatDueDate(DateTime dueDate, AppLocalizations loc) {
    return DateFormat.yMMMd(loc.isRTL ? 'ar' : 'en').format(dueDate);
  }
}

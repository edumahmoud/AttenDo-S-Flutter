import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Todos State ───

class TodosState {
  final List<UserTodo> todos;
  final bool isLoading;
  final bool isCreating;
  final String? error;

  const TodosState({
    this.todos = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.error,
  });

  List<UserTodo> get pendingTodos =>
      todos.where((t) => !t.isCompleted).toList();

  List<UserTodo> get completedTodos =>
      todos.where((t) => t.isCompleted).toList();

  List<UserTodo> get overdueTodos => pendingTodos
      .where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
      .toList();

  List<UserTodo> get todayTodos => pendingTodos.where((t) {
        final now = DateTime.now();
        return t.dueDate != null &&
            t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day;
      }).toList();

  TodosState copyWith({
    List<UserTodo>? todos,
    bool? isLoading,
    bool? isCreating,
    String? error,
    bool clearError = false,
  }) {
    return TodosState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Todos Controller ───

class TodosController extends StateNotifier<TodosState> {
  final StudentApiService _apiService;

  TodosController(this._apiService) : super(const TodosState()) {
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final todos = await _apiService.fetchTodos();
      state = state.copyWith(todos: todos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<bool> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    TodoCategory? category,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final todo = await _apiService.createTodo({
        'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        'priority': (priority ?? TodoPriority.medium).name,
        'category': (category ?? TodoCategory.other).name,
        'source': 'manual',
      });
      state = state.copyWith(
        todos: [todo, ...state.todos],
        isCreating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> updateTodo(String id, Map<String, dynamic> data) async {
    final previousTodos = state.todos;
    // Optimistic update
    state = state.copyWith(
      todos: state.todos.map((t) {
        if (t.id == id) {
          return t.copyWith(
            title: data['title'] as String? ?? t.title,
            description:
                data.containsKey('description') ? data['description'] as String? : t.description,
            dueDate: data.containsKey('dueDate')
                ? (data['dueDate'] != null
                    ? DateTime.parse(data['dueDate'] as String)
                    : null)
                : t.dueDate,
            priority: data.containsKey('priority')
                ? TodoPriority.values.firstWhere(
                    (e) => e.name == data['priority'],
                    orElse: () => t.priority,
                  )
                : t.priority,
            category: data.containsKey('category')
                ? TodoCategory.values.firstWhere(
                    (e) => e.name == data['category'],
                    orElse: () => t.category,
                  )
                : t.category,
          );
        }
        return t;
      }).toList(),
    );
    try {
      await _apiService.updateTodo(id, data);
      return true;
    } catch (e) {
      state = state.copyWith(todos: previousTodos, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> toggleTodo(String id) async {
    final previousTodos = state.todos;
    final todo = state.todos.firstWhere((t) => t.id == id);
    final newCompleted = !todo.isCompleted;

    // Optimistic toggle
    state = state.copyWith(
      todos: state.todos
          .map((t) => t.id == id
              ? t.copyWith(
                  isCompleted: newCompleted,
                  completedAt: newCompleted ? DateTime.now() : null,
                )
              : t)
          .toList(),
    );
    try {
      await _apiService.updateTodo(id, {
        'isCompleted': newCompleted,
        if (newCompleted) 'completedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      state = state.copyWith(todos: previousTodos, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    final previousTodos = state.todos;
    state = state.copyWith(todos: state.todos.where((t) => t.id != id).toList());
    try {
      await _apiService.deleteTodo(id);
      return true;
    } catch (e) {
      state = state.copyWith(todos: previousTodos, error: _friendlyError(e));
      return false;
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to update todo. Please try again.';
  }
}

// ─── Provider ───

final todosControllerProvider =
    StateNotifierProvider<TodosController, TodosState>((ref) {
  return TodosController(ref.watch(studentApiServiceProvider));
});

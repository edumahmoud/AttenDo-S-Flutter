enum TodoPriority { low, medium, high, urgent }

enum TodoCategory { study, assignment, exam, personal, project, other }

enum TodoSource { manual, assignment, quiz, system }

class UserTodo {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TodoPriority priority;
  final TodoCategory category;
  final TodoSource source;
  final String? subjectId;
  final String? referenceId;
  final String? referenceType;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTodo({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.category,
    required this.source,
    this.subjectId,
    this.referenceId,
    this.referenceType,
    required this.isCompleted,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserTodo.fromJson(Map<String, dynamic> json) {
    return UserTodo(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: _priorityFromString(json['priority'] as String),
      category: _categoryFromString(json['category'] as String),
      source: _sourceFromString(json['source'] as String),
      subjectId: json['subjectId'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'category': category.name,
      'source': source.name,
      'subjectId': subjectId,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserTodo copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TodoPriority? priority,
    TodoCategory? category,
    TodoSource? source,
    String? subjectId,
    String? referenceId,
    String? referenceType,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserTodo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      source: source ?? this.source,
      subjectId: subjectId ?? this.subjectId,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TodoPriority _priorityFromString(String value) {
    return TodoPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TodoPriority.medium,
    );
  }

  static TodoCategory _categoryFromString(String value) {
    return TodoCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TodoCategory.other,
    );
  }

  static TodoSource _sourceFromString(String value) {
    return TodoSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TodoSource.manual,
    );
  }
}

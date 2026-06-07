enum CalendarEventType {
  lecture,
  quiz,
  assignment,
  exam,
  meeting,
  event,
  holiday,
  other,
}

class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final CalendarEventType type;
  final DateTime startDate;
  final DateTime? endDate;
  final String? subjectId;
  final String? referenceId;
  final String? referenceType;
  final String? color;
  final String? location;
  final bool? isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    this.subjectId,
    this.referenceId,
    this.referenceType,
    this.color,
    this.location,
    this.isAllDay,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: _typeFromString(json['type'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      subjectId: json['subjectId'] as String?,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      color: json['color'] as String?,
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool?,
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
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'subjectId': subjectId,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'color': color,
      'location': location,
      'isAllDay': isAllDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? subjectId,
    String? referenceId,
    String? referenceType,
    String? color,
    String? location,
    bool? isAllDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      subjectId: subjectId ?? this.subjectId,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      color: color ?? this.color,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static CalendarEventType _typeFromString(String value) {
    return CalendarEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CalendarEventType.other,
    );
  }
}

enum NotificationType {
  quizAssigned,
  assignmentCreated,
  assignmentGraded,
  attendanceMarked,
  summaryReady,
  messageReceived,
  reportUpdated,
  announcement,
  system,
}

class DBNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  const DBNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory DBNotification.fromJson(Map<String, dynamic> json) {
    return DBNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: _typeFromString(json['type'] as String),
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': _typeToString(type),
      'referenceId': referenceId,
      'referenceType': referenceType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DBNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? referenceId,
    String? referenceType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return DBNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static NotificationType _typeFromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }

  static String _typeToString(NotificationType type) {
    return type.name;
  }
}

enum ReportStatus { open, inProgress, resolved, closed }

enum ReportPriority { low, medium, high, critical }

enum ReportType { bug, feature, complaint, question, other }

class ReportMessage {
  final String id;
  final String reportId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final DateTime createdAt;

  const ReportMessage({
    required this.id,
    required this.reportId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ReportMessage.fromJson(Map<String, dynamic> json) {
    return ReportMessage(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'senderId': senderId,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReportMessage copyWith({
    String? id,
    String? reportId,
    String? senderId,
    String? content,
    String? attachmentUrl,
    DateTime? createdAt,
  }) {
    return ReportMessage(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReportResponse {
  final String id;
  final String reportId;
  final String responderId;
  final String content;
  final DateTime createdAt;

  const ReportResponse({
    required this.id,
    required this.reportId,
    required this.responderId,
    required this.content,
    required this.createdAt,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      responderId: json['responderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'responderId': responderId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReportResponse copyWith({
    String? id,
    String? reportId,
    String? responderId,
    String? content,
    DateTime? createdAt,
  }) {
    return ReportResponse(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      responderId: responderId ?? this.responderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ReportType type;
  final ReportStatus status;
  final ReportPriority priority;
  final String? subjectId;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReportResponse>? responses;
  final List<ReportMessage>? messages;

  const Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    this.subjectId,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.responses,
    this.messages,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: _typeFromString(json['type'] as String),
      status: _statusFromString(json['status'] as String),
      priority: _priorityFromString(json['priority'] as String),
      subjectId: json['subjectId'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      responses: json['responses'] != null
          ? (json['responses'] as List)
              .map((e) => ReportResponse.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((e) => ReportMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'subjectId': subjectId,
      'attachmentUrl': attachmentUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'responses': responses?.map((e) => e.toJson()).toList(),
      'messages': messages?.map((e) => e.toJson()).toList(),
    };
  }

  Report copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ReportType? type,
    ReportStatus? status,
    ReportPriority? priority,
    String? subjectId,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReportResponse>? responses,
    List<ReportMessage>? messages,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      subjectId: subjectId ?? this.subjectId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      responses: responses ?? this.responses,
      messages: messages ?? this.messages,
    );
  }

  static ReportType _typeFromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportType.other,
    );
  }

  static ReportStatus _statusFromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.open,
    );
  }

  static ReportPriority _priorityFromString(String value) {
    return ReportPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportPriority.medium,
    );
  }
}

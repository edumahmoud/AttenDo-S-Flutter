enum AttendanceStatus { present, absent, late, excused }

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final String? note;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      status: _statusFromString(json['status'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': _statusToString(status),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    AttendanceStatus? status,
    String? note,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static AttendanceStatus _statusFromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttendanceStatus.absent,
    );
  }

  static String _statusToString(AttendanceStatus status) {
    return status.name;
  }
}

class AttendanceSession {
  final String id;
  final String subjectId;
  final String teacherId;
  final DateTime date;
  final String? title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AttendanceRecord>? records;

  const AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.date,
    this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.records,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      teacherId: json['teacherId'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      records: json['records'] != null
          ? (json['records'] as List)
              .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'records': records?.map((e) => e.toJson()).toList(),
    };
  }

  AttendanceSession copyWith({
    String? id,
    String? subjectId,
    String? teacherId,
    DateTime? date,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AttendanceRecord>? records,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      records: records ?? this.records,
    );
  }
}

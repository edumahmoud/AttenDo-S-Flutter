class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final double? grade;
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.fileUrl,
    this.fileName,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      content: json['content'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      feedback: json['feedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'grade': grade,
      'feedback': feedback,
      'submittedAt': submittedAt?.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Submission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? content,
    String? fileUrl,
    String? fileName,
    double? grade,
    String? feedback,
    DateTime? submittedAt,
    DateTime? gradedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Submission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Assignment {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String? lectureId;
  final String createdBy;
  final DateTime? dueDate;
  final double? maxGrade;
  final bool? isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Submission>? submissions;

  const Assignment({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.lectureId,
    required this.createdBy,
    this.dueDate,
    this.maxGrade,
    this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.submissions,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lectureId: json['lectureId'] as String?,
      createdBy: json['createdBy'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      maxGrade: json['maxGrade'] != null
          ? (json['maxGrade'] as num).toDouble()
          : null,
      isPublished: json['isPublished'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      submissions: json['submissions'] != null
          ? (json['submissions'] as List)
              .map((e) => Submission.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'lectureId': lectureId,
      'createdBy': createdBy,
      'dueDate': dueDate?.toIso8601String(),
      'maxGrade': maxGrade,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'submissions': submissions?.map((e) => e.toJson()).toList(),
    };
  }

  Assignment copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? lectureId,
    String? createdBy,
    DateTime? dueDate,
    double? maxGrade,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Submission>? submissions,
  }) {
    return Assignment(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      lectureId: lectureId ?? this.lectureId,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      maxGrade: maxGrade ?? this.maxGrade,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submissions: submissions ?? this.submissions,
    );
  }
}

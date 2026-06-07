class TeacherStudentLink {
  final String id;
  final String teacherId;
  final String studentId;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  const TeacherStudentLink({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.status,
    required this.createdAt,
  });

  factory TeacherStudentLink.fromJson(Map<String, dynamic> json) {
    return TeacherStudentLink(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      studentId: json['studentId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'studentId': studentId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TeacherStudentLink copyWith({
    String? id,
    String? teacherId,
    String? studentId,
    String? status,
    DateTime? createdAt,
  }) {
    return TeacherStudentLink(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

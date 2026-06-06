class StudentPerformance {
  final String id;
  final String studentId;
  final String subjectId;
  final double? averageScore;
  final double? attendanceRate;
  final int? quizzesTaken;
  final int? assignmentsCompleted;
  final int? totalAssignments;
  final double? quizAverage;
  final double? assignmentAverage;
  final String? grade;
  final String? performanceLevel; // excellent, good, average, below_average
  final DateTime? lastCalculated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentPerformance({
    required this.id,
    required this.studentId,
    required this.subjectId,
    this.averageScore,
    this.attendanceRate,
    this.quizzesTaken,
    this.assignmentsCompleted,
    this.totalAssignments,
    this.quizAverage,
    this.assignmentAverage,
    this.grade,
    this.performanceLevel,
    this.lastCalculated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      subjectId: json['subjectId'] as String,
      averageScore: json['averageScore'] != null
          ? (json['averageScore'] as num).toDouble()
          : null,
      attendanceRate: json['attendanceRate'] != null
          ? (json['attendanceRate'] as num).toDouble()
          : null,
      quizzesTaken: json['quizzesTaken'] as int?,
      assignmentsCompleted: json['assignmentsCompleted'] as int?,
      totalAssignments: json['totalAssignments'] as int?,
      quizAverage: json['quizAverage'] != null
          ? (json['quizAverage'] as num).toDouble()
          : null,
      assignmentAverage: json['assignmentAverage'] != null
          ? (json['assignmentAverage'] as num).toDouble()
          : null,
      grade: json['grade'] as String?,
      performanceLevel: json['performanceLevel'] as String?,
      lastCalculated: json['lastCalculated'] != null
          ? DateTime.parse(json['lastCalculated'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'subjectId': subjectId,
      'averageScore': averageScore,
      'attendanceRate': attendanceRate,
      'quizzesTaken': quizzesTaken,
      'assignmentsCompleted': assignmentsCompleted,
      'totalAssignments': totalAssignments,
      'quizAverage': quizAverage,
      'assignmentAverage': assignmentAverage,
      'grade': grade,
      'performanceLevel': performanceLevel,
      'lastCalculated': lastCalculated?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  StudentPerformance copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    double? averageScore,
    double? attendanceRate,
    int? quizzesTaken,
    int? assignmentsCompleted,
    int? totalAssignments,
    double? quizAverage,
    double? assignmentAverage,
    String? grade,
    String? performanceLevel,
    DateTime? lastCalculated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentPerformance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      averageScore: averageScore ?? this.averageScore,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      assignmentsCompleted: assignmentsCompleted ?? this.assignmentsCompleted,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      quizAverage: quizAverage ?? this.quizAverage,
      assignmentAverage: assignmentAverage ?? this.assignmentAverage,
      grade: grade ?? this.grade,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      lastCalculated: lastCalculated ?? this.lastCalculated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

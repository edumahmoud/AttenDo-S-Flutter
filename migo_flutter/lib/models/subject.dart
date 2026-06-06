class Subject {
  final String id;
  final String name;
  final String? description;
  final String? code;
  final String? teacherId;
  final String? color;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.teacherId,
    this.color,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      code: json['code'] as String?,
      teacherId: json['teacher_id'] as String?,
      color: json['color'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'teacher_id': teacherId,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

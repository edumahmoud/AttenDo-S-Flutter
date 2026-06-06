class Summary {
  final String id;
  final String userId;
  final String title;
  final String originalContent;
  final String summaryContent;
  final String? subjectId;
  final String? sourceFileType; // pdf, docx, pptx, txt
  final String? sourceFileUrl;
  final DateTime createdAt;

  const Summary({
    required this.id,
    required this.userId,
    required this.title,
    required this.originalContent,
    required this.summaryContent,
    this.subjectId,
    this.sourceFileType,
    this.sourceFileUrl,
    required this.createdAt,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      originalContent: json['originalContent'] as String,
      summaryContent: json['summaryContent'] as String,
      subjectId: json['subjectId'] as String?,
      sourceFileType: json['sourceFileType'] as String?,
      sourceFileUrl: json['sourceFileUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'originalContent': originalContent,
      'summaryContent': summaryContent,
      'subjectId': subjectId,
      'sourceFileType': sourceFileType,
      'sourceFileUrl': sourceFileUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Summary copyWith({
    String? id,
    String? userId,
    String? title,
    String? originalContent,
    String? summaryContent,
    String? subjectId,
    String? sourceFileType,
    String? sourceFileUrl,
    DateTime? createdAt,
  }) {
    return Summary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      originalContent: originalContent ?? this.originalContent,
      summaryContent: summaryContent ?? this.summaryContent,
      subjectId: subjectId ?? this.subjectId,
      sourceFileType: sourceFileType ?? this.sourceFileType,
      sourceFileUrl: sourceFileUrl ?? this.sourceFileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

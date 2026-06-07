class VideoComment {
  final String id;
  final String videoId;
  final String userId;
  final String content;
  final int? timestampSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.content,
    this.timestampSeconds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      timestampSeconds: json['timestampSeconds'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'content': content,
      'timestampSeconds': timestampSeconds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  VideoComment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? content,
    int? timestampSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoComment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubjectVideo {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? categoryId;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<VideoComment>? comments;

  const SubjectVideo({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.categoryId,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.comments,
  });

  factory SubjectVideo.fromJson(Map<String, dynamic> json) {
    return SubjectVideo(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      categoryId: json['categoryId'] as String?,
      uploadedBy: json['uploadedBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((e) => VideoComment.fromJson(e as Map<String, dynamic>))
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
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'categoryId': categoryId,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'comments': comments?.map((e) => e.toJson()).toList(),
    };
  }

  SubjectVideo copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? categoryId,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<VideoComment>? comments,
  }) {
    return SubjectVideo(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      categoryId: categoryId ?? this.categoryId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
    );
  }
}

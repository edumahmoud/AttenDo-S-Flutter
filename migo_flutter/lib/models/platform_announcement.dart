enum AnnouncementPriority { low, normal, high, critical }

enum AnnouncementType { info, maintenance, update, feature, warning }

class PlatformAnnouncementView {
  final String id;
  final String announcementId;
  final String userId;
  final DateTime viewedAt;

  const PlatformAnnouncementView({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.viewedAt,
  });

  factory PlatformAnnouncementView.fromJson(Map<String, dynamic> json) {
    return PlatformAnnouncementView(
      id: json['id'] as String,
      announcementId: json['announcementId'] as String,
      userId: json['userId'] as String,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'announcementId': announcementId,
      'userId': userId,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  PlatformAnnouncementView copyWith({
    String? id,
    String? announcementId,
    String? userId,
    DateTime? viewedAt,
  }) {
    return PlatformAnnouncementView(
      id: id ?? this.id,
      announcementId: announcementId ?? this.announcementId,
      userId: userId ?? this.userId,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}

class PlatformAnnouncement {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final AnnouncementPriority priority;
  final String? imageUrl;
  final String? linkUrl;
  final String? createdBy;
  final bool isPinned;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlatformAnnouncementView>? views;

  const PlatformAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    this.imageUrl,
    this.linkUrl,
    this.createdBy,
    required this.isPinned,
    this.startsAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.views,
  });

  factory PlatformAnnouncement.fromJson(Map<String, dynamic> json) {
    return PlatformAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: _typeFromString(json['type'] as String),
      priority: _priorityFromString(json['priority'] as String),
      imageUrl: json['imageUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      createdBy: json['createdBy'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      startsAt: json['startsAt'] != null
          ? DateTime.parse(json['startsAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      views: json['views'] != null
          ? (json['views'] as List)
              .map((e) =>
                  PlatformAnnouncementView.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'priority': priority.name,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'createdBy': createdBy,
      'isPinned': isPinned,
      'startsAt': startsAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'views': views?.map((e) => e.toJson()).toList(),
    };
  }

  PlatformAnnouncement copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementType? type,
    AnnouncementPriority? priority,
    String? imageUrl,
    String? linkUrl,
    String? createdBy,
    bool? isPinned,
    DateTime? startsAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlatformAnnouncementView>? views,
  }) {
    return PlatformAnnouncement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      createdBy: createdBy ?? this.createdBy,
      isPinned: isPinned ?? this.isPinned,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
    );
  }

  static AnnouncementType _typeFromString(String value) {
    return AnnouncementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnnouncementType.info,
    );
  }

  static AnnouncementPriority _priorityFromString(String value) {
    return AnnouncementPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnnouncementPriority.normal,
    );
  }
}

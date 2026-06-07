enum PollType { single, multiple }

enum PollStatus { draft, active, closed }

class PollOption {
  final String id;
  final String pollId;
  final String text;
  final int? orderIndex;
  final DateTime createdAt;

  const PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    this.orderIndex,
    required this.createdAt,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      text: json['text'] as String,
      orderIndex: json['orderIndex'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollId': pollId,
      'text': text,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PollOption copyWith({
    String? id,
    String? pollId,
    String? text,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      text: text ?? this.text,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PollResponse {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;
  final DateTime createdAt;

  const PollResponse({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.createdAt,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      optionId: json['optionId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollId': pollId,
      'optionId': optionId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PollResponse copyWith({
    String? id,
    String? pollId,
    String? optionId,
    String? userId,
    DateTime? createdAt,
  }) {
    return PollResponse(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      optionId: optionId ?? this.optionId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Poll {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String createdBy;
  final PollType type;
  final PollStatus status;
  final bool? isAnonymous;
  final DateTime? closesAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PollOption>? options;
  final List<PollResponse>? responses;

  const Poll({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.createdBy,
    required this.type,
    required this.status,
    this.isAnonymous,
    this.closesAt,
    required this.createdAt,
    required this.updatedAt,
    this.options,
    this.responses,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String,
      type: _typeFromString(json['type'] as String),
      status: _statusFromString(json['status'] as String),
      isAnonymous: json['isAnonymous'] as bool?,
      closesAt: json['closesAt'] != null
          ? DateTime.parse(json['closesAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      responses: json['responses'] != null
          ? (json['responses'] as List)
              .map((e) => PollResponse.fromJson(e as Map<String, dynamic>))
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
      'createdBy': createdBy,
      'type': type.name,
      'status': status.name,
      'isAnonymous': isAnonymous,
      'closesAt': closesAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'options': options?.map((e) => e.toJson()).toList(),
      'responses': responses?.map((e) => e.toJson()).toList(),
    };
  }

  Poll copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? createdBy,
    PollType? type,
    PollStatus? status,
    bool? isAnonymous,
    DateTime? closesAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PollOption>? options,
    List<PollResponse>? responses,
  }) {
    return Poll(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      closesAt: closesAt ?? this.closesAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      options: options ?? this.options,
      responses: responses ?? this.responses,
    );
  }

  static PollType _typeFromString(String value) {
    return PollType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PollType.single,
    );
  }

  static PollStatus _statusFromString(String value) {
    return PollStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PollStatus.draft,
    );
  }
}

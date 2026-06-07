class UserFolder {
  final String id;
  final String userId;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserFolder({
    required this.id,
    required this.userId,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserFolder.fromJson(Map<String, dynamic> json) {
    return UserFolder(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserFolder copyWith({
    String? id,
    String? userId,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserFolder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserFile {
  final String id;
  final String userId;
  final String name;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? folderId;
  final String? subjectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserFile({
    required this.id,
    required this.userId,
    required this.name,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.folderId,
    this.subjectId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserFile.fromJson(Map<String, dynamic> json) {
    return UserFile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      folderId: json['folderId'] as String?,
      subjectId: json['subjectId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'folderId': folderId,
      'subjectId': subjectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserFile copyWith({
    String? id,
    String? userId,
    String? name,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    String? folderId,
    String? subjectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      folderId: folderId ?? this.folderId,
      subjectId: subjectId ?? this.subjectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubjectFile {
  final String id;
  final String subjectId;
  final String name;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? categoryId;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubjectFile({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.categoryId,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectFile.fromJson(Map<String, dynamic> json) {
    return SubjectFile(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      categoryId: json['categoryId'] as String?,
      uploadedBy: json['uploadedBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'categoryId': categoryId,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SubjectFile copyWith({
    String? id,
    String? subjectId,
    String? name,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    String? categoryId,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectFile(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      categoryId: categoryId ?? this.categoryId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FileShare {
  final String id;
  final String fileId;
  final String sharedBy;
  final String sharedWith;
  final String? permission; // view, edit
  final DateTime createdAt;

  const FileShare({
    required this.id,
    required this.fileId,
    required this.sharedBy,
    required this.sharedWith,
    this.permission,
    required this.createdAt,
  });

  factory FileShare.fromJson(Map<String, dynamic> json) {
    return FileShare(
      id: json['id'] as String,
      fileId: json['fileId'] as String,
      sharedBy: json['sharedBy'] as String,
      sharedWith: json['sharedWith'] as String,
      permission: json['permission'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileId': fileId,
      'sharedBy': sharedBy,
      'sharedWith': sharedWith,
      'permission': permission,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FileShare copyWith({
    String? id,
    String? fileId,
    String? sharedBy,
    String? sharedWith,
    String? permission,
    DateTime? createdAt,
  }) {
    return FileShare(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedWith: sharedWith ?? this.sharedWith,
      permission: permission ?? this.permission,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

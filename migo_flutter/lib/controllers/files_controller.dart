import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Files State ───

class FilesState {
  final List<UserFile> files;
  final List<UserFolder> folders;
  final String? currentFolderId;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const FilesState({
    this.files = const [],
    this.folders = const [],
    this.currentFolderId,
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
  });

  /// Files in the current folder (or root if null).
  List<UserFile> get currentFiles => files
      .where((f) => f.folderId == currentFolderId)
      .toList();

  /// Subfolders in the current folder (or root if null).
  List<UserFolder> get currentSubfolders => folders
      .where((f) => f.parentId == currentFolderId)
      .toList();

  /// Total file count.
  int get totalFileCount => files.length;

  FilesState copyWith({
    List<UserFile>? files,
    List<UserFolder>? folders,
    String? currentFolderId,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    bool clearError = false,
    bool clearCurrentFolder = false,
  }) {
    return FilesState(
      files: files ?? this.files,
      folders: folders ?? this.folders,
      currentFolderId: clearCurrentFolder
          ? null
          : (currentFolderId ?? this.currentFolderId),
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Files Controller ───

class FilesController extends StateNotifier<FilesState> {
  final FileService _fileService;
  final SupabaseService _supabaseService;

  FilesController(
    this._fileService,
    this._supabaseService,
  ) : super(const FilesState()) {
    fetchFiles();
  }

  Future<void> fetchFiles([String? folderId]) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentFolderId: folderId,
    );
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Fetch files
      var filesQuery = _supabaseService.client
          .from('user_files')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final filesData = await filesQuery;
      final files = (filesData as List<dynamic>)
          .map((json) => UserFile.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fetch folders
      final foldersData = await _supabaseService.client
          .from('user_folders')
          .select()
          .eq('user_id', userId)
          .order('name');

      final folders = (foldersData as List<dynamic>)
          .map((json) => UserFolder.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        files: files,
        folders: folders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<bool> createFolder(String name, [String? parentFolderId]) async {
    state = state.copyWith(clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final result = await _supabaseService.client
          .from('user_folders')
          .insert({
            'user_id': userId,
            'name': name,
            if (parentFolderId != null) 'parent_id': parentFolderId,
          })
          .select()
          .single();

      final folder = UserFolder.fromJson(result);
      state = state.copyWith(folders: [...state.folders, folder]);
      return true;
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> uploadFile(String filePath, [String? folderId]) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final fileName = filePath.split('/').last;
      final storagePath = 'users/$userId/files/$fileName';

      // Upload to storage
      await _fileService.uploadFile(
        filePath: filePath,
        bucket: AppConstants.materialsBucket,
        path: storagePath,
      );

      final publicUrl = _fileService.getPublicUrl(
        bucket: AppConstants.materialsBucket,
        path: storagePath,
      );

      // Create file record
      final result = await _supabaseService.client
          .from('user_files')
          .insert({
            'user_id': userId,
            'name': fileName,
            'file_url': publicUrl,
            'file_type': fileName.contains('.') ? fileName.split('.').last : '',
            'file_size': 0, // Will be updated by backend
            if (folderId != null) 'folder_id': folderId,
          })
          .select()
          .single();

      final file = UserFile.fromJson(result);
      state = state.copyWith(
        files: [file, ...state.files],
        isUploading: false,
        uploadProgress: 1.0,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: _friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> deleteFile(String fileId) async {
    final previousFiles = state.files;
    state = state.copyWith(files: state.files.where((f) => f.id != fileId).toList());
    try {
      await _supabaseService.client
          .from('user_files')
          .delete()
          .eq('id', fileId);
      return true;
    } catch (e) {
      state = state.copyWith(files: previousFiles, error: _friendlyError(e));
      return false;
    }
  }

  Future<bool> shareFile(String fileId, String userId, String permission) async {
    state = state.copyWith(clearError: true);
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) throw Exception('Not authenticated');

      await _supabaseService.client.from('file_shares').insert({
        'file_id': fileId,
        'shared_by': currentUserId,
        'shared_with': userId,
        'permission': permission,
      });
      return true;
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      return false;
    }
  }

  void navigateToFolder(String? folderId) {
    state = state.copyWith(currentFolderId: folderId);
  }

  void navigateUp() {
    if (state.currentFolderId == null) return;
    final matched = state.folders
        .where((f) => f.id == state.currentFolderId);
    if (matched.isEmpty) {
      state = state.copyWith(currentFolderId: null);
    } else {
      state = state.copyWith(currentFolderId: matched.first.parentId);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('too large') || msg.contains('exceeds')) {
      return 'File is too large. Maximum size is ${AppConstants.maxFileSizeMB}MB.';
    }
    return 'Failed to manage files. Please try again.';
  }
}

// ─── Provider ───

final filesControllerProvider =
    StateNotifierProvider<FilesController, FilesState>((ref) {
  return FilesController(
    ref.watch(fileServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

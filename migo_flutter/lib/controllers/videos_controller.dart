import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Videos State ───

class VideosState {
  final List<SubjectVideo> videos;
  final String? selectedSubjectId;
  final bool isLoading;
  final String? error;

  const VideosState({
    this.videos = const [],
    this.selectedSubjectId,
    this.isLoading = false,
    this.error,
  });

  /// Videos filtered by the selected subject (or all if null).
  List<SubjectVideo> get filteredVideos {
    if (selectedSubjectId == null || selectedSubjectId == 'all') return videos;
    return videos.where((v) => v.subjectId == selectedSubjectId).toList();
  }

  VideosState copyWith({
    List<SubjectVideo>? videos,
    String? selectedSubjectId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedSubject = false,
  }) {
    return VideosState(
      videos: videos ?? this.videos,
      selectedSubjectId: clearSelectedSubject
          ? null
          : (selectedSubjectId ?? this.selectedSubjectId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Videos Controller ───

class VideosController extends StateNotifier<VideosState> {
  final SupabaseService _supabaseService;

  VideosController(
    this._supabaseService,
  ) : super(const VideosState()) {
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Fetch subject IDs for the student
      final subjectData = await _supabaseService.client
          .from('student_subjects')
          .select('subject_id')
          .eq('student_id', userId);

      final subjectIds = (subjectData as List<dynamic>)
          .map((row) => row['subject_id'] as String)
          .toList();

      if (subjectIds.isEmpty) {
        state = state.copyWith(videos: [], isLoading: false);
        return;
      }

      // Fetch videos for those subjects
      final data = await _supabaseService.client
          .from('subject_videos')
          .select()
          .inFilter('subject_id', subjectIds)
          .order('created_at', ascending: false)
          .limit(AppConstants.defaultPageSize * 2);

      final videos = (data as List<dynamic>)
          .map((json) => SubjectVideo.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(videos: videos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> addComment(String videoId, String content) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabaseService.client.from('video_comments').insert({
        'video_id': videoId,
        'user_id': userId,
        'content': content.trim(),
      });

      // Refresh videos to get updated comments
      await fetchVideos();
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
    }
  }

  void filterBySubject(String? subjectId) {
    state = state.copyWith(selectedSubjectId: subjectId);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load videos. Please try again.';
  }
}

// ─── Provider ───

final videosControllerProvider =
    StateNotifierProvider<VideosController, VideosState>((ref) {
  return VideosController(
    ref.watch(supabaseServiceProvider),
  );
});

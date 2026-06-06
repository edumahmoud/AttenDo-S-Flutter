import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../i18n/app_localizations.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';
import '../shared/empty_state.dart';

// ────────────────────────────────────────────────────────────
// Videos Screen – Subject Videos Browser
// ────────────────────────────────────────────────────────────

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    // Ensure subjects are loaded for the filter dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsControllerProvider.notifier).fetchSubjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubjectVideo> _filterVideos(List<SubjectVideo> videos) {
    var filtered = videos;
    if (_selectedSubjectId != null && _selectedSubjectId != 'all') {
      filtered = filtered
          .where((v) => v.subjectId == _selectedSubjectId)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((v) =>
              v.title.toLowerCase().contains(q) ||
              (v.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final videosState = ref.watch(videosControllerProvider);
    final subjectsState = ref.watch(subjectsControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(videosControllerProvider.notifier).fetchVideos(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Header + Search + Filter ───
          SliverToBoxAdapter(
            child: _buildHeader(videosState, subjectsState, loc, theme),
          ),

          // ─── Content ───
          if (videosState.isLoading && videosState.videos.isEmpty)
            SliverToBoxAdapter(child: _buildLoadingState())
          else if (videosState.error != null && videosState.videos.isEmpty)
            SliverToBoxAdapter(
              child: SectionErrorBoundary(
                message: videosState.error,
                onRetry: () => ref
                    .read(videosControllerProvider.notifier)
                    .fetchVideos(),
              ),
            )
          else if (videosState.videos.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(loc),
            )
          else
            _buildVideosGrid(_filterVideos(videosState.videos), subjectsState, loc, theme),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(
    VideosState videoState,
    SubjectsState subjectsState,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Text(
            '${loc.t('videos.title')} (${videoState.videos.length})',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: loc.t('common.search') + '...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Subject filter dropdown
          if (subjectsState.subjects.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: _selectedSubjectId ?? 'all',
                decoration: InputDecoration(
                  labelText: loc.t('nav.subjects'),
                  prefixIcon: const Icon(LucideIcons.filter, size: 18),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(loc.t('common.filter') +
                        ': ${loc.t('nav.subjects')}'),
                  ),
                  ...subjectsState.subjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedSubjectId = v);
                  ref
                      .read(videosControllerProvider.notifier)
                      .filterBySubject(v);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Loading State ───

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
        children: List.generate(4, (_) => const LoadingShimmerCardBlock()),
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState(AppLocalizations loc) {
    return EmptyState(
      icon: LucideIcons.video,
      title: loc.t('videos.noVideos'),
    );
  }

  // ─── Videos Grid ───

  Widget _buildVideosGrid(
    List<SubjectVideo> videos,
    SubjectsState subjectsState,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.sizeOf(context).width >= 768 ? 3 : 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _VideoCard(
              video: videos[index],
              subjectName: _getSubjectName(
                  videos[index].subjectId, subjectsState),
              onTap: () => _showVideoDetail(
                  videos[index], subjectsState, loc, theme),
            );
          },
          childCount: videos.length,
        ),
      ),
    );
  }

  String _getSubjectName(String subjectId, SubjectsState subjectsState) {
    final subject = subjectsState.subjects
        .where((s) => s.id == subjectId);
    return subject.isEmpty ? '' : subject.first.name;
  }

  // ─── Video Detail Bottom Sheet ───

  void _showVideoDetail(
    SubjectVideo video,
    SubjectsState subjectsState,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final subjectName = _getSubjectName(video.subjectId, subjectsState);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // ─── Thumbnail / Play Button ───
                          _VideoThumbnail(
                            video: video,
                            onTap: () => _playVideo(video),
                          ),

                          const SizedBox(height: 16),

                          // ─── Title ───
                          Text(
                            video.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ─── Subject Badge + Stats ───
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (subjectName.isNotEmpty)
                                _InfoChip(
                                  icon: LucideIcons.bookOpen,
                                  label: subjectName,
                                  color: AppColors.ocean(theme.brightness),
                                ),
                              if (video.durationSeconds != null)
                                _InfoChip(
                                  icon: LucideIcons.clock,
                                  label: _formatDuration(
                                      video.durationSeconds!),
                                  color: AppColors.tealAccent(
                                      theme.brightness),
                                ),
                              _InfoChip(
                                icon: LucideIcons.calendar,
                                label: _formatTimeAgo(
                                    video.createdAt, loc),
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ─── Description ───
                          if (video.description != null &&
                              video.description!.isNotEmpty) ...[
                            Text(
                              video.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ─── Play Button ───
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _playVideo(video),
                              icon: const Icon(LucideIcons.play, size: 20),
                              label: Text(loc.t('videos.play')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.ocean(theme.brightness),
                                foregroundColor: AppColors.oceanForeground(
                                    theme.brightness),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      AppTheme.borderRadiusGeometry,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─── Comments Section ───
                          Text(
                            loc.t('videos.comments'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Comments list
                          if (video.comments != null &&
                              video.comments!.isNotEmpty)
                            ...video.comments!.map((comment) =>
                                _CommentCard(
                                    comment: comment, theme: theme))
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              child: Text(
                                loc.t('videos.noComments'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Add comment
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: commentController,
                                  decoration: InputDecoration(
                                    hintText:
                                        loc.t('videos.addComment'),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  final content =
                                      commentController.text.trim();
                                  if (content.isEmpty) return;
                                  commentController.clear();
                                  await ref
                                      .read(videosControllerProvider
                                          .notifier)
                                      .addComment(video.id, content);
                                  if (context.mounted) {
                                    setSheetState(() {});
                                  }
                                },
                                icon: Icon(LucideIcons.send,
                                    color: AppColors.ocean(
                                        theme.brightness)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _playVideo(SubjectVideo video) async {
    try {
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).t('common.errorUnexpected')),
          ),
        );
      }
    }
  }
}

// ────────────────────────────────────────────────────────────
// Video Card
// ────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final SubjectVideo video;
  final String subjectName;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.subjectName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    return Card(
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Thumbnail ───
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail or placeholder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.borderRadius)),
                    child: video.thumbnailUrl != null &&
                            video.thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(LucideIcons.video,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(LucideIcons.video,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : Container(
                            color: oceanColor.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(LucideIcons.playCircle,
                                  size: 40, color: oceanColor),
                            ),
                          ),
                  ),

                  // Play icon overlay
                  if (video.thumbnailUrl != null)
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.play,
                            size: 20, color: Colors.white),
                      ),
                    ),

                  // Duration badge
                  if (video.durationSeconds != null)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.durationSeconds!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Info ───
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      video.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Subject badge
                    if (subjectName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: oceanColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subjectName,
                          style:
                              theme.textTheme.labelSmall?.copyWith(
                            color: oceanColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Date
                    Text(
                      _formatTimeAgo(video.createdAt,
                          AppLocalizations.of(context)),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Video Thumbnail (for detail sheet)
// ────────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  final SubjectVideo video;
  final VoidCallback onTap;

  const _VideoThumbnail({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppTheme.borderRadiusGeometry,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnailUrl != null &&
                  video.thumbnailUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(LucideIcons.video,
                          size: 48,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(LucideIcons.video,
                          size: 48,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Container(
                  color: oceanColor.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(LucideIcons.playCircle,
                        size: 64, color: oceanColor),
                  ),
                ),
              // Play button overlay
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.play,
                      size: 28, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Info Chip
// ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Comment Card
// ────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final VideoComment comment;
  final ThemeData theme;

  const _CommentCard({required this.comment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: oceanColor.withValues(alpha: 0.15),
            child: Icon(LucideIcons.user, size: 14, color: oceanColor),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userId,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt, loc),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Flag comment button
                    InkWell(
                      onTap: () {
                        // Flag comment logic placeholder
                      },
                      child: Icon(
                        LucideIcons.flag,
                        size: 14,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

String _formatDuration(int seconds) {
  final hrs = seconds ~/ 3600;
  final mins = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hrs > 0) {
    return '${hrs}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${mins}:${secs.toString().padLeft(2, '0')}';
}

String _formatTimeAgo(DateTime dt, AppLocalizations loc) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return loc.t('time.justNow');
  if (diff.inMinutes < 60) {
    return loc.t('time.minutesAgo', args: {'n': diff.inMinutes.toString()});
  }
  if (diff.inHours < 24) {
    return loc.t('time.hoursAgo', args: {'n': diff.inHours.toString()});
  }
  if (diff.inDays < 7) {
    return loc.t('time.daysAgo', args: {'n': diff.inDays.toString()});
  }
  if (diff.inDays < 30) {
    return loc.t('time.weeksAgo',
        args: {'n': (diff.inDays ~/ 7).toString()});
  }
  return '${dt.day}/${dt.month}/${dt.year}';
}

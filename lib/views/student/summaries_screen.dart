import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../i18n/app_localizations.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ────────────────────────────────────────────────────────────────
// Summaries Screen
// ────────────────────────────────────────────────────────────────

class SummariesScreen extends ConsumerStatefulWidget {
  const SummariesScreen({super.key});

  @override
  ConsumerState<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends ConsumerState<SummariesScreen>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  String? _selectedSummaryId;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // ─── Helpers ───

  String _relativeDate(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return loc.t('time.justNow');
    if (diff.inMinutes < 60) {
      return loc.t('time.minutesAgo', args: {'n': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return loc.t('time.hoursAgo', args: {'n': diff.inHours.toString()});
    }
    if (diff.inDays < 30) {
      return loc.t('time.daysAgo', args: {'n': diff.inDays.toString()});
    }
    return loc.t('time.monthsAgo', args: {'n': (diff.inDays ~/ 30).toString()});
  }

  IconData _sourceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.article_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Color _sourceTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
      case 'doc':
        return Colors.blue;
      case 'pptx':
      case 'ppt':
        return Colors.orange;
      default:
        return AppColors.lightTealAccent;
    }
  }

  String _sourceTypeLabel(String? type) {
    return type?.toUpperCase() ?? 'TEXT';
  }

  // ─── Refresh ───

  Future<void> _onRefresh() async {
    await ref.read(summariesControllerProvider.notifier).fetchSummaries();
    _refreshController.refreshCompleted();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(summariesControllerProvider);
    final theme = Theme.of(context);

    // If a summary is selected, show detail view
    if (_selectedSummaryId != null) {
      final summary = state.summaries.where((s) => s.id == _selectedSummaryId).firstOrNull;
      if (summary != null) {
        return _SummaryDetailView(
          summary: summary,
          isPending: state.pendingSummaryIds.contains(summary.id),
          onBack: () => setState(() => _selectedSummaryId = null),
        );
      }
    }

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: _buildHeader(context, loc, state, theme),
              ),

              // ─── Error ───
              if (state.error != null && state.summaries.isEmpty)
                SliverFillRemaining(
                  child: SectionErrorBoundary(
                    message: state.error,
                    onRetry: () =>
                        ref.read(summariesControllerProvider.notifier).fetchSummaries(),
                  ),
                ),

              // ─── Loading shimmer ───
              if (state.isLoading && state.summaries.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LoadingShimmerCardBlock(),
                      ),
                      childCount: 4,
                    ),
                  ),
                ),

              // ─── Pending summaries ───
              if (state.pendingSummaryIds.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildPendingSection(context, loc, state, theme),
                ),

              // ─── Empty state ───
              if (!state.isLoading && state.summaries.isEmpty && state.error == null)
                SliverFillRemaining(
                  child: _buildEmptyState(context, loc, theme),
                ),

              // ─── Summary list ───
              if (state.summaries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final summary = state.summaries[index];
                        return _SummaryCard(
                          summary: summary,
                          isPending: state.pendingSummaryIds.contains(summary.id),
                          relativeDate: _relativeDate(context, summary.createdAt),
                          sourceTypeIcon: _sourceTypeIcon(summary.sourceFileType),
                          sourceTypeColor: _sourceTypeColor(summary.sourceFileType),
                          sourceTypeLabel: _sourceTypeLabel(summary.sourceFileType),
                          onTap: () => setState(() => _selectedSummaryId = summary.id),
                          onDelete: () => _confirmDelete(context, loc, summary),
                          onRename: () => _showRenameDialog(context, loc, summary),
                          onGenerateQuiz: () => _showQuizConfigModal(context, loc, summary),
                        );
                      },
                      childCount: state.summaries.length,
                    ),
                  ),
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),

        // ─── FAB ───
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusGeometry,
            gradient: const LinearGradient(
              colors: [AppColors.lightOcean, AppColors.lightTealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightOcean.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'createSummary',
            onPressed: () => _showCreateSummaryModal(context, loc),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: Text(
              loc.t('student.createSummaryBtn'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(BuildContext context, AppLocalizations loc,
      SummariesState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('student.summariesTitle'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.t('student.summariesDesc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.summaries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.summaries.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Pending section ───

  Widget _buildPendingSection(BuildContext context, AppLocalizations loc,
      SummariesState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.t('summary.analyzing'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.pendingSummaryIds.map((id) {
            final summary = state.summaries.where((s) => s.id == id).firstOrNull;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summary?.title ?? loc.t('summary.pleaseWait'),
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Empty state ───

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.summarize_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              loc.t('student.noSummaries'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('student.createFirstSummary'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateSummaryModal(context, loc),
              icon: const Icon(Icons.add_rounded),
              label: Text(loc.t('student.createSummaryBtn')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete confirmation ───

  void _confirmDelete(BuildContext context, AppLocalizations loc, Summary summary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('summary.deleteSummary')),
        content: Text(
          loc.t('summary.deleteSummaryConfirm', args: {'title': summary.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(summariesControllerProvider.notifier).deleteSummary(summary.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
  }

  // ─── Rename dialog ───

  void _showRenameDialog(BuildContext context, AppLocalizations loc, Summary summary) {
    final controller = TextEditingController(text: summary.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('files.rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: summary.title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != summary.title) {
                ref.read(summariesControllerProvider.notifier).renameSummary(summary.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text(loc.commonSave),
          ),
        ],
      ),
    );
  }

  // ─── Create Summary Modal ───

  void _showCreateSummaryModal(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CreateSummarySheet(loc: loc),
    );
  }

  // ─── Quiz Config Modal ───

  void _showQuizConfigModal(BuildContext context, AppLocalizations loc, Summary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _QuizConfigSheet(
        loc: loc,
        summary: summary,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Summary Card
// ────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final Summary summary;
  final bool isPending;
  final String relativeDate;
  final IconData sourceTypeIcon;
  final Color sourceTypeColor;
  final String sourceTypeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onGenerateQuiz;

  const _SummaryCard({
    required this.summary,
    required this.isPending,
    required this.relativeDate,
    required this.sourceTypeIcon,
    required this.sourceTypeColor,
    required this.sourceTypeLabel,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onGenerateQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusGeometry,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top row: title + badges ───
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Source type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sourceTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sourceTypeIcon, size: 12, color: sourceTypeColor),
                        const SizedBox(width: 4),
                        Text(
                          sourceTypeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: sourceTypeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Subject badge
              if (summary.subjectId != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_rounded,
                        size: 12,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        summary.subjectId!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Preview
              Text(
                summary.summaryContent,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Date
              Text(
                relativeDate,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const Divider(height: 24),

              // Action buttons
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.visibility_rounded,
                    label: AppLocalizations.of(context).t('common.view'),
                    onTap: onTap,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.quiz_rounded,
                    label: AppLocalizations.of(context).t('student.createQuiz'),
                    onTap: onGenerateQuiz,
                    color: AppColors.lightTealAccent,
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    label: AppLocalizations.of(context).t('files.rename'),
                    onTap: onRename,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: AppLocalizations.of(context).t('common.delete'),
                    onTap: onDelete,
                    color: theme.colorScheme.error,
                  ),
                ],
              ),

              // Pending indicator
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).t('summary.analyzing'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Action Button (compact)
// ────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
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
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Create Summary Bottom Sheet
// ────────────────────────────────────────────────────────────────

class _CreateSummarySheet extends ConsumerStatefulWidget {
  final AppLocalizations loc;

  const _CreateSummarySheet({required this.loc});

  @override
  ConsumerState<_CreateSummarySheet> createState() => _CreateSummarySheetState();
}

class _CreateSummarySheetState extends ConsumerState<_CreateSummarySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _selectedExistingFileId;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'doc', 'ppt', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _generateSummary({required String sourceType, String? content}) async {
    if (sourceType == 'text' && (content == null || content.trim().isEmpty)) return;
    if (sourceType == 'file' && _selectedFilePath == null) return;
    if (sourceType == 'existing' && _selectedExistingFileId == null) return;

    setState(() => _isGenerating = true);
    try {
      await ref.read(summariesControllerProvider.notifier).createSummary(
            content: content ?? _selectedFileName ?? 'existing_file',
            sourceType: sourceType,
            subjectId: _selectedSubjectId,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.t('common.toastCreated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.t('common.toastError'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final theme = Theme.of(context);
    final subjectsState = ref.watch(subjectsControllerProvider);
    final filesState = ref.watch(filesControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Tab bar ───
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: loc.t('summary.transcribedText')),
                Tab(text: loc.t('files.upload')),
                Tab(text: loc.t('student.statFiles')),
              ],
            ),
            const SizedBox(height: 8),

            // ─── Tab views ───
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── From Text ──
                  _buildFromTextTab(theme, loc, subjectsState),
                  // ── From File ──
                  _buildFromFileTab(theme, loc),
                  // ── From Existing File ──
                  _buildFromExistingFileTab(theme, loc, filesState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFromTextTab(
      ThemeData theme, AppLocalizations loc, SubjectsState subjectsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: loc.t('todo.todoTitle'),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: loc.t('summary.transcribedText'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          // Subject dropdown
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: InputDecoration(
              labelText: loc.t('nav.subjects'),
              prefixIcon: const Icon(Icons.book_rounded),
            ),
            items: [
              DropdownMenuItem<String>(
                child: Text('${loc.t('common.filter')} - ${loc.t('nav.subjects')}'),
              ),
              ...subjectsState.subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedSubjectId = v),
          ),
          const SizedBox(height: 20),
          _buildGenerateButton(
            theme: theme,
            loc: loc,
            onPressed: _isGenerating
                ? null
                : () => _generateSummary(
                      sourceType: 'text',
                      content: _contentController.text,
                    ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFromFileTab(ThemeData theme, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // File picker area
          InkWell(
            onTap: _pickFile,
            borderRadius: AppTheme.borderRadiusGeometry,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline,
                  style: BorderStyle.solid,
                ),
                borderRadius: AppTheme.borderRadiusGeometry,
              ),
              child: _selectedFileName != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFileName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _pickFile,
                            child: Text(loc.t('common.edit')),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload_rounded,
                            size: 44,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.t('files.upload'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF, DOCX, PPTX',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _buildGenerateButton(
            theme: theme,
            loc: loc,
            onPressed: _selectedFilePath != null && !_isGenerating
                ? () => _generateSummary(sourceType: 'file')
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFromExistingFileTab(
      ThemeData theme, AppLocalizations loc, FilesState filesState) {
    final supportedFiles = filesState.files
        .where((f) => ['pdf', 'docx', 'pptx', 'doc', 'ppt', 'txt']
            .contains(f.fileType.toLowerCase()))
        .toList();

    return Column(
      children: [
        Expanded(
          child: supportedFiles.isEmpty
              ? Center(
                  child: Text(
                    loc.t('files.noFiles'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: supportedFiles.length,
                  itemBuilder: (context, index) {
                    final file = supportedFiles[index];
                    final isSelected = _selectedExistingFileId == file.id;
                    return Card(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          _fileTypeIcon(file.fileType),
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          file.fileType.toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: theme.colorScheme.primary)
                            : null,
                        onTap: () =>
                            setState(() => _selectedExistingFileId = file.id),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _buildGenerateButton(
            theme: theme,
            loc: loc,
            onPressed: _selectedExistingFileId != null && !_isGenerating
                ? () => _generateSummary(sourceType: 'existing')
                : null,
          ),
        ),
      ],
    );
  }

  IconData _fileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildGenerateButton({
    required ThemeData theme,
    required AppLocalizations loc,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusGeometry,
          ),
        ),
        child: _isGenerating
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(loc.t('summary.analyzing')),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(loc.t('student.createSummaryBtn')),
                ],
              ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Quiz Config Modal
// ────────────────────────────────────────────────────────────────

class _QuizConfigSheet extends ConsumerStatefulWidget {
  final AppLocalizations loc;
  final Summary summary;

  const _QuizConfigSheet({
    required this.loc,
    required this.summary,
  });

  @override
  ConsumerState<_QuizConfigSheet> createState() => _QuizConfigSheetState();
}

class _QuizConfigSheetState extends ConsumerState<_QuizConfigSheet> {
  double _mcqCount = 5;
  double _tfCount = 3;
  double _completionCount = 2;
  double _matchingCount = 1;
  bool _showAnswersDuring = true;
  bool _allowRetake = true;
  bool _shuffleQuestions = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: loc.textDirection,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightTealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: AppColors.lightTealAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.t('summary.createQuiz'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // MCQ slider
              _buildSlider(
                theme: theme,
                label: loc.t('summary.multipleChoice'),
                value: _mcqCount,
                max: 20,
                onChanged: (v) => setState(() => _mcqCount = v),
              ),
              const SizedBox(height: 16),

              // True/False slider
              _buildSlider(
                theme: theme,
                label: loc.t('summary.trueFalse'),
                value: _tfCount,
                max: 10,
                onChanged: (v) => setState(() => _tfCount = v),
              ),
              const SizedBox(height: 16),

              // Completion slider
              _buildSlider(
                theme: theme,
                label: loc.t('summary.fillBlank'),
                value: _completionCount,
                max: 10,
                onChanged: (v) => setState(() => _completionCount = v),
              ),
              const SizedBox(height: 16),

              // Matching slider
              _buildSlider(
                theme: theme,
                label: loc.t('summary.matching'),
                value: _matchingCount,
                max: 5,
                onChanged: (v) => setState(() => _matchingCount = v),
              ),
              const SizedBox(height: 20),

              // Toggles
              _buildToggle(
                theme: theme,
                label: loc.t('summary.showAnswers'),
                subtitle: loc.t('quiz.reviewAnswers'),
                value: _showAnswersDuring,
                onChanged: (v) => setState(() => _showAnswersDuring = v),
              ),
              _buildToggle(
                theme: theme,
                label: loc.t('summary.allowRetake'),
                value: _allowRetake,
                onChanged: (v) => setState(() => _allowRetake = v),
              ),
              _buildToggle(
                theme: theme,
                label: loc.t('summary.shuffleQuestions'),
                value: _shuffleQuestions,
                onChanged: (v) => setState(() => _shuffleQuestions = v),
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightTealAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusGeometry,
                    ),
                  ),
                  child: _isGenerating
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(loc.t('common.creating')),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(loc.t('summary.createQuiz')),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required ThemeData theme,
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toInt().toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: max,
          divisions: max.toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggle({
    required ThemeData theme,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _generateQuiz() async {
    setState(() => _isGenerating = true);
    try {
      await ref.read(summariesControllerProvider.notifier).generateQuizFromSummary(
            widget.summary.id,
            config: {
              'mcqCount': _mcqCount.toInt(),
              'tfCount': _tfCount.toInt(),
              'completionCount': _completionCount.toInt(),
              'matchingCount': _matchingCount.toInt(),
              'showAnswersDuring': _showAnswersDuring,
              'allowRetake': _allowRetake,
              'shuffleQuestions': _shuffleQuestions,
            },
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.t('summary.quizCreated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.loc.t('summary.quizCreateError'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

// ────────────────────────────────────────────────────────────────
// Summary Detail View
// ────────────────────────────────────────────────────────────────

class _SummaryDetailView extends ConsumerStatefulWidget {
  final Summary summary;
  final bool isPending;
  final VoidCallback onBack;

  const _SummaryDetailView({
    required this.summary,
    required this.isPending,
    required this.onBack,
  });

  @override
  ConsumerState<_SummaryDetailView> createState() => _SummaryDetailViewState();
}

class _SummaryDetailViewState extends ConsumerState<_SummaryDetailView> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
          title: Text(
            widget.summary.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Rename
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: loc.t('files.rename'),
              onPressed: () => _showRenameDialog(context, loc),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: loc.t('common.delete'),
              onPressed: () => _confirmDelete(context, loc),
            ),
            // Generate Quiz
            IconButton(
              icon: const Icon(Icons.quiz_rounded),
              tooltip: loc.t('student.createQuiz'),
              onPressed: () => _showQuizConfig(context, loc),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Meta badges ───
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.summary.subjectId != null)
                    Chip(
                      avatar: const Icon(Icons.book_rounded, size: 16),
                      label: Text(widget.summary.subjectId!),
                    ),
                  Chip(
                    avatar: Icon(
                      _sourceTypeIcon(widget.summary.sourceFileType),
                      size: 16,
                    ),
                    label: Text(
                      (widget.summary.sourceFileType ?? 'text').toUpperCase(),
                    ),
                  ),
                  if (widget.isPending)
                    Chip(
                      avatar: const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: Text(loc.t('summary.analyzing')),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── AI-generated badge ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightTealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.lightTealAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.t('summary.generatedByAi'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.lightTealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Summary Content (Markdown) ───
              Text(
                loc.t('summary.studySummary'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: AppTheme.borderRadiusGeometry,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: MarkdownBody(
                  data: widget.summary.summaryContent,
                  selectable: true,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Original content toggle ───
              InkWell(
                onTap: () => setState(() => _showOriginal = !_showOriginal),
                borderRadius: AppTheme.borderRadiusGeometry,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppTheme.borderRadiusGeometry,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showOriginal
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.t('summary.transcribedText'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showOriginal) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: AppTheme.borderRadiusGeometry,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    widget.summary.originalContent,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _sourceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  void _showRenameDialog(BuildContext context, AppLocalizations loc) {
    final controller = TextEditingController(text: widget.summary.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('files.rename')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref
                    .read(summariesControllerProvider.notifier)
                    .renameSummary(widget.summary.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text(loc.commonSave),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('summary.deleteSummary')),
        content: Text(
          loc.t('summary.deleteSummaryConfirm',
              args: {'title': widget.summary.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(summariesControllerProvider.notifier)
                  .deleteSummary(widget.summary.id);
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
  }

  void _showQuizConfig(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _QuizConfigSheet(
        loc: loc,
        summary: widget.summary,
      ),
    );
  }
}

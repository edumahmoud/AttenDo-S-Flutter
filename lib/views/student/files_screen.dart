import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../i18n/app_localizations.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';
import '../shared/empty_state.dart';

// ────────────────────────────────────────────────────────────
// Files Screen – My Files + Shared With Me
// ────────────────────────────────────────────────────────────

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filesState = ref.watch(filesControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ─── Header ───
        _buildHeader(filesState, loc, theme),

        // ─── Tab Bar ───
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppTheme.borderRadiusGeometry,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.ocean(theme.brightness),
              borderRadius: AppTheme.borderRadiusGeometry,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: loc.t('files.title')),
              Tab(text: loc.t('files.sharedWithMe')),
            ],
          ),
        ),

        // ─── Tab Content ───
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyFilesTab(filesState, loc, theme),
              _buildSharedWithMeTab(loc, theme),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header ───

  Widget _buildHeader(FilesState state, AppLocalizations loc, ThemeData theme) {
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);
    final oceanFg = AppColors.oceanForeground(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  '${loc.t('files.title')} (${state.totalFileCount})',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // View toggle
              _ViewToggle(
                isGridView: _isGridView,
                onToggle: (isGrid) =>
                    setState(() => _isGridView = isGrid),
                theme: theme,
                loc: loc,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showNewFolderDialog(loc, theme),
                  icon: const Icon(LucideIcons.folderPlus, size: 18),
                  label: Text(loc.t('files.newFolder')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusGeometry,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUploadFileDialog(loc, theme),
                  icon: const Icon(LucideIcons.upload, size: 18),
                  label: Text(loc.t('files.upload')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oceanColor,
                    foregroundColor: oceanFg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusGeometry,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: loc.t('files.searchFiles'),
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

          // ─── Breadcrumb ───
          if (state.currentFolderId != null)
            _buildBreadcrumb(state, loc, theme),
        ],
      ),
    );
  }

  // ─── Breadcrumb Navigation ───

  Widget _buildBreadcrumb(FilesState state, AppLocalizations loc, ThemeData theme) {
    final path = <String>[];
    String? folderId = state.currentFolderId;

    // Build folder path
    while (folderId != null) {
      final folder = state.folders.where((f) => f.id == folderId);
      if (folder.isEmpty) break;
      path.insert(0, folder.first.name);
      folderId = folder.first.parentId;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InkWell(
            onTap: () => ref
                .read(filesControllerProvider.notifier)
                .navigateToFolder(null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.home, size: 16,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 2),
                Text(
                  loc.t('files.title'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < path.length; i++) ...[
            Icon(LucideIcons.chevronRight, size: 14,
                color: theme.colorScheme.onSurfaceVariant),
            InkWell(
              onTap: i == path.length - 1
                  ? null
                  : () {
                      // Navigate to this folder level
                      // Find the folder ID for this level
                      String? targetId;
                      for (final f in state.folders) {
                        if (f.name == path[i]) {
                          targetId = f.id;
                          break;
                        }
                      }
                      if (targetId != null) {
                        ref
                            .read(filesControllerProvider.notifier)
                            .navigateToFolder(targetId);
                      }
                    },
              child: Text(
                path[i],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: i == path.length - 1
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.primary,
                  fontWeight: i == path.length - 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── My Files Tab ───

  Widget _buildMyFilesTab(
      FilesState state, AppLocalizations loc, ThemeData theme) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return SectionErrorBoundary(
        message: state.error,
        onRetry: () =>
            ref.read(filesControllerProvider.notifier).fetchFiles(),
      );
    }

    final subfolders = state.currentSubfolders;
    var files = state.currentFiles;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      files = files
          .where((f) => f.name.toLowerCase().contains(q))
          .toList();
    }

    if (subfolders.isEmpty && files.isEmpty) {
      return EmptyState(
        icon: LucideIcons.folderOpen,
        title: loc.t('files.noFiles'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(filesControllerProvider.notifier).fetchFiles(),
      child: _isGridView
          ? _buildGridView(subfolders, files, theme, loc)
          : _buildListView(subfolders, files, theme, loc),
    );
  }

  // ─── Grid View ───

  Widget _buildGridView(
    List<UserFolder> folders,
    List<UserFile> files,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 768 ? 4 : 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return _FolderGridCard(
            folder: folders[index],
            onTap: () => ref
                .read(filesControllerProvider.notifier)
                .navigateToFolder(folders[index].id),
            onLongPress: () =>
                _showFolderOptions(folders[index], loc, theme),
          );
        }
        final file = files[index - folders.length];
        return _FileGridCard(
          file: file,
          onTap: () => _openFile(file),
          onLongPress: () => _showFileOptions(file, loc, theme),
        );
      },
    );
  }

  // ─── List View ───

  Widget _buildListView(
    List<UserFolder> folders,
    List<UserFile> files,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return _FolderListTile(
            folder: folders[index],
            onTap: () => ref
                .read(filesControllerProvider.notifier)
                .navigateToFolder(folders[index].id),
            onLongPress: () =>
                _showFolderOptions(folders[index], loc, theme),
          );
        }
        final file = files[index - folders.length];
        return _FileListTile(
          file: file,
          onTap: () => _openFile(file),
          onLongPress: () => _showFileOptions(file, loc, theme),
          loc: loc,
          theme: theme,
        );
      },
    );
  }

  // ─── Shared With Me Tab ───

  Widget _buildSharedWithMeTab(AppLocalizations loc, ThemeData theme) {
    // For now, display a placeholder until shared files are loaded
    return EmptyState(
      icon: LucideIcons.share2,
      title: loc.t('files.sharedWithMe'),
      description: loc.t('files.noFiles'),
    );
  }

  // ─── Loading State ───

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: List.generate(6, (_) => const LoadingShimmerCardBlock()),
      ),
    );
  }

  // ─── File Actions ───

  void _openFile(UserFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).t('common.errorUnexpected'))),
        );
      }
    }
  }

  void _showFileOptions(
      UserFile file, AppLocalizations loc, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.download),
              title: Text(loc.t('files.download')),
              onTap: () {
                Navigator.pop(context);
                _openFile(file);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: Text(loc.t('files.share')),
              onTap: () {
                Navigator.pop(context);
                // Share file logic placeholder
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2,
                  color: theme.colorScheme.error),
              title: Text(loc.t('files.delete'),
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _confirmDelete(loc);
                if (confirmed == true) {
                  final success = await ref
                      .read(filesControllerProvider.notifier)
                      .deleteFile(file.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? loc.t('common.toastDeleted')
                            : loc.t('common.errorUnexpected')),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderOptions(
      UserFolder folder, AppLocalizations loc, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text(loc.t('files.rename')),
              onTap: () {
                Navigator.pop(context);
                // Rename folder logic placeholder
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2,
                  color: theme.colorScheme.error),
              title: Text(loc.t('files.delete'),
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                // Delete folder logic placeholder
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(AppLocalizations loc) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('files.delete')),
        content: Text(loc.t('common.confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
  }

  // ─── New Folder Dialog ───

  void _showNewFolderDialog(AppLocalizations loc, ThemeData theme) {
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(loc.t('files.newFolder')),
              content: TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.t('files.folderName'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => isCreating = true);
                          final currentFolderId = ref
                              .read(filesControllerProvider)
                              .currentFolderId;
                          final success = await ref
                              .read(filesControllerProvider.notifier)
                              .createFolder(name, currentFolderId);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? loc.t('common.toastCreated')
                                      : loc.t('common.errorUnexpected')),
                                ),
                              );
                            }
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(loc.t('files.createFolder')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Upload File Dialog ───

  void _showUploadFileDialog(AppLocalizations loc, ThemeData theme) {
    String? selectedFilePath;
    String? selectedFileName;
    String? selectedFolderId;
    bool isUploading = false;

    final filesState = ref.read(filesControllerProvider);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(loc.t('files.upload')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File picker button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final file =
                            await ref.read(fileServiceProvider).pickFile();
                        if (file != null) {
                          setDialogState(() {
                            selectedFilePath = file.path;
                            selectedFileName =
                                file.path.split('/').last;
                          });
                        }
                      },
                      icon: const Icon(LucideIcons.fileUp, size: 18),
                      label: Text(loc.t('files.upload')),
                    ),
                  ),

                  // Selected file name
                  if (selectedFileName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppTheme.borderRadiusGeometry,
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.file, size: 18,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFileName!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Folder selector
                  if (filesState.folders.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedFolderId,
                      decoration: InputDecoration(
                        labelText: loc.t('files.moveToFolder'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(loc.t('files.title')),
                        ),
                        ...filesState.folders.map((f) =>
                            DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name),
                            )),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedFolderId = v),
                    ),

                  // Size limit hint
                  const SizedBox(height: 8),
                  Text(
                    loc.t('files.maxFileSize'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  // Upload progress
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: ref.read(filesControllerProvider).uploadProgress,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.t('files.uploading'),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isUploading ? null : () => Navigator.pop(dialogContext),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isUploading || selectedFilePath == null
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);
                          final success = await ref
                              .read(filesControllerProvider.notifier)
                              .uploadFile(
                                  selectedFilePath!, selectedFolderId);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? loc.t('files.uploadSuccess')
                                      : loc.t('files.uploadError')),
                                ),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(loc.t('files.upload')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────
// View Toggle
// ────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool isGridView;
  final ValueChanged<bool> onToggle;
  final ThemeData theme;
  final AppLocalizations loc;

  const _ViewToggle({
    required this.isGridView,
    required this.onToggle,
    required this.theme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: AppTheme.borderRadiusGeometry,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(LucideIcons.layoutGrid, isGridView, loc.t('files.gridView')),
          _toggleBtn(LucideIcons.list, !isGridView, loc.t('files.listView')),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onToggle(icon == LucideIcons.layoutGrid),
        borderRadius: BorderRadius.horizontal(
          left: icon == LucideIcons.layoutGrid
              ? const Radius.circular(AppTheme.borderRadius)
              : Radius.zero,
          right: icon == LucideIcons.list
              ? const Radius.circular(AppTheme.borderRadius)
              : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.ocean(theme.brightness)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: icon == LucideIcons.layoutGrid
                  ? const Radius.circular(AppTheme.borderRadius - 1)
                  : Radius.zero,
              right: icon == LucideIcons.list
                  ? const Radius.circular(AppTheme.borderRadius - 1)
                  : Radius.zero,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? AppColors.oceanForeground(theme.brightness)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Folder Grid Card
// ────────────────────────────────────────────────────────────

class _FolderGridCard extends StatelessWidget {
  final UserFolder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FolderGridCard({
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.folder,
                  size: 36,
                  color: AppColors.amberAccent(theme.brightness)),
              const SizedBox(height: 8),
              Text(
                folder.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// File Grid Card
// ────────────────────────────────────────────────────────────

class _FileGridCard extends StatelessWidget {
  final UserFile file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileGridCard({
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileColor = _fileColor(theme.brightness);
    final fileIcon = _fileIcon;

    return Card(
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fileIcon, size: 36, color: fileColor),
              const SizedBox(height: 8),
              Text(
                file.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatFileSize(file.fileSize),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _fileIcon {
    final ext = file.fileType.toLowerCase();
    switch (ext) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'doc':
      case 'docx':
        return LucideIcons.fileType;
      case 'ppt':
      case 'pptx':
        return LucideIcons.presentation;
      case 'xls':
      case 'xlsx':
        return LucideIcons.table;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return LucideIcons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return LucideIcons.video;
      case 'mp3':
      case 'wav':
        return LucideIcons.music;
      case 'zip':
      case 'rar':
        return LucideIcons.archive;
      default:
        return LucideIcons.file;
    }
  }

  Color _fileColor(Brightness brightness) {
    final ext = file.fileType.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.teal;
      case 'mp4':
      case 'mov':
        return Colors.purple;
      default:
        return AppColors.ocean(brightness);
    }
  }
}

// ────────────────────────────────────────────────────────────
// Folder List Tile
// ────────────────────────────────────────────────────────────

class _FolderListTile extends StatelessWidget {
  final UserFolder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FolderListTile({
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(LucideIcons.folder,
            size: 28,
            color: AppColors.amberAccent(theme.brightness)),
        title: Text(
          folder.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusGeometry),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// File List Tile
// ────────────────────────────────────────────────────────────

class _FileListTile extends StatelessWidget {
  final UserFile file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final AppLocalizations loc;
  final ThemeData theme;

  const _FileListTile({
    required this.file,
    required this.onTap,
    required this.onLongPress,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final gridCard = _FileGridCard(
      file: file,
      onTap: onTap,
      onLongPress: onLongPress,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(gridCard._fileIcon,
            size: 28, color: gridCard._fileColor(theme.brightness)),
        title: Text(
          file.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              _formatFileSize(file.fileSize),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(file.updatedAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  const Icon(LucideIcons.download, size: 16),
                  const SizedBox(width: 8),
                  Text(loc.t('files.download')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(LucideIcons.share2, size: 16),
                  const SizedBox(width: 8),
                  Text(loc.t('files.share')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2,
                      size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(loc.t('files.delete'),
                      style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'download':
                onTap();
                break;
              case 'share':
                // Share logic placeholder
                break;
              case 'delete':
                // Delete logic placeholder
                break;
            }
          },
        ),
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusGeometry),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

String _formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  int unitIndex = 0;
  double size = bytes.toDouble();
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../controllers/controllers.dart';
import '../../models/models.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../i18n/app_localizations.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';
import '../shared/empty_state.dart';

// ────────────────────────────────────────────────────────────
// Subjects Listing Screen
// ────────────────────────────────────────────────────────────

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Subject> _filterSubjects(List<Subject> subjects) {
    if (_searchQuery.isEmpty) return subjects;
    final q = _searchQuery.toLowerCase();
    return subjects
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            (s.description?.toLowerCase().contains(q) ?? false) ||
            (s.code?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(subjectsControllerProvider.notifier).fetchSubjects(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Header + Search ───
          SliverToBoxAdapter(
            child: _buildHeader(subjectsState, loc, theme),
          ),

          // ─── Content ───
          if (subjectsState.isLoading && subjectsState.subjects.isEmpty)
            SliverToBoxAdapter(
              child: _buildLoadingState(),
            )
          else if (subjectsState.error != null &&
              subjectsState.subjects.isEmpty)
            SliverToBoxAdapter(
              child: SectionErrorBoundary(
                message: subjectsState.error,
                onRetry: () => ref
                    .read(subjectsControllerProvider.notifier)
                    .fetchSubjects(),
              ),
            )
          else if (subjectsState.subjects.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(loc),
            )
          else
            _buildSubjectsGrid(_filterSubjects(subjectsState.subjects)),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(
    SubjectsState state,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  '${loc.t('nav.subjects')} (${state.subjects.length})',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showJoinSubjectDialog(loc),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(loc.t('student.joinSubject')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oceanColor,
                  foregroundColor: AppColors.oceanForeground(brightness),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusGeometry,
                  ),
                ),
              ),
            ],
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
        childAspectRatio: 0.85,
        children: List.generate(4, (_) => const LoadingShimmerCardBlock()),
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState(AppLocalizations loc) {
    return EmptyState(
      icon: LucideIcons.bookOpen,
      title: loc.t('student.noSubjects'),
      description: loc.t('student.joinFirstSubject'),
      actionLabel: loc.t('student.joinSubject'),
      onAction: () => _showJoinSubjectDialog(loc),
    );
  }

  // ─── Subjects Grid ───

  Widget _buildSubjectsGrid(List<Subject> subjects) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 768 ? 3 : 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _SubjectCard(
              subject: subjects[index],
              onTap: () => _navigateToCourse(subjects[index]),
              onLongPress: () => _showSubjectOptions(subjects[index]),
            );
          },
          childCount: subjects.length,
        ),
      ),
    );
  }

  // ─── Navigate to Course ───

  void _navigateToCourse(Subject subject) {
    ref.read(subjectsControllerProvider.notifier).selectSubject(subject.id);
    context.go('/student/subjects/${subject.id}');
  }

  // ─── Subject Options (Long Press) ───

  void _showSubjectOptions(Subject subject) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: Colors.red),
                title: Text(
                  loc.t('student.leaveSubject'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _confirmLeave(subject, loc);
                  if (confirmed == true) {
                    final success = await ref
                        .read(subjectsControllerProvider.notifier)
                        .leaveSubject(subject.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? loc.t('student.leftSubject')
                                : loc.t('common.errorUnexpected'),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmLeave(Subject subject, AppLocalizations loc) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('student.leaveSubject')),
        content: Text(
          loc.t('student.leaveSubjectConfirm', args: {
            'name': subject.name,
          }),
        ),
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
            child: Text(loc.commonConfirm),
          ),
        ],
      ),
    );
  }

  // ─── Join Subject Dialog ───

  void _showJoinSubjectDialog(AppLocalizations loc) {
    final codeController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(loc.t('student.joinSubject')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.t('student.joinSubjectDesc'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    decoration: InputDecoration(
                      hintText: loc.t('student.subjectCodePlaceholder'),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      codeController.value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: TextSelection.collapsed(
                          offset: value.toUpperCase().length,
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isJoining ? null : () => Navigator.pop(dialogContext),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: isJoining
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.length < 4) return;

                          setDialogState(() => isJoining = true);
                          final success = await ref
                              .read(subjectsControllerProvider.notifier)
                              .joinSubject(code);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? loc.t('student.joinSubjectSuccess')
                                      : loc.t('common.errorUnexpected'),
                                ),
                              ),
                            );
                          }
                        },
                  child: isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(loc.t('student.joinSubject')),
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
// Subject Card
// ────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SubjectCard({
    required this.subject,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _subjectColor {
    if (subject.color != null) {
      final hex = subject.color!.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return AppColors.lightOcean;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusGeometry,
            border: BorderDirectional(
              start: BorderSide(
                color: _subjectColor,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name
              Text(
                subject.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Teacher name (placeholder, since Subject model only has teacherId)
              Row(
                children: [
                  Icon(LucideIcons.user, size: 14,
                      color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subject.teacherId ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Code badge
              if (subject.code != null)
                Row(
                  children: [
                    Icon(LucideIcons.hash, size: 14,
                        color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject.code!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // Description (if available)
              if (subject.description != null &&
                  subject.description!.isNotEmpty)
                Text(
                  subject.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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

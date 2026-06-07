import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../../controllers/controllers.dart';
import '../../i18n/app_localizations.dart';
import '../../models/models.dart';
import '../shared/empty_state.dart';
import '../shared/loading_shimmer.dart';
import '../shared/section_error_boundary.dart';

// ─── Teachers Screen ───

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(teachersControllerProvider);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            ref.read(teachersControllerProvider.notifier).fetchLinkedTeachers();
            ref
                .read(teachersControllerProvider.notifier)
                .fetchIncomingLinkRequests();
          },
          child: CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(child: _buildHeader(loc, state)),

              // ─── Error banner ───
              if (state.actionError != null)
                SliverToBoxAdapter(child: _buildErrorBanner(loc, state)),

              // ─── Linked Teachers ───
              SliverToBoxAdapter(child: _buildLinkedSectionTitle(loc, state)),
              _buildLinkedTeachersList(loc, state),

              // ─── Incoming Requests ───
              SliverToBoxAdapter(
                  child: _buildIncomingRequestsTitle(loc, state)),
              _buildIncomingRequestsList(loc, state),

              // ─── Pending Requests (sent by student) ───
              SliverToBoxAdapter(
                  child: _buildPendingRequestsTitle(loc, state)),
              _buildPendingRequestsList(loc, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(AppLocalizations loc, TeachersState state) {
    final theme = Theme.of(context);
    final count = state.linkedTeachers.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${loc.t('student.teachersTitle')} ($count)',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showLinkTeacherDialog(loc),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(loc.t('student.linkNewTeacher')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error Banner ───

  Widget _buildErrorBanner(AppLocalizations loc, TeachersState state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: AppColors.lightDestructive.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusGeometry,
          side: BorderSide(
              color: AppColors.lightDestructive.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 18, color: AppColors.lightDestructive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.actionError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightDestructive,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16,
                    color: AppColors.lightDestructive.withValues(alpha: 0.7)),
                onPressed: () {
                  // Clear error by re-fetching
                  ref
                      .read(teachersControllerProvider.notifier)
                      .fetchLinkedTeachers();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Linked Teachers Section ───

  Widget _buildLinkedSectionTitle(AppLocalizations loc, TeachersState state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        loc.t('student.teachersTitle'),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildLinkedTeachersList(AppLocalizations loc, TeachersState state) {
    if (state.isLoadingTeachers) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(
                3,
                (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LoadingShimmerCardBlock())),
          ),
        ),
      );
    }

    if (state.teachersError != null) {
      return SliverToBoxAdapter(
        child: SectionErrorBoundary(
          message: state.teachersError,
          onRetry: () => ref
              .read(teachersControllerProvider.notifier)
              .fetchLinkedTeachers(),
        ),
      );
    }

    if (state.linkedTeachers.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.person_add_outlined,
          title: loc.t('student.noTeachers'),
          description: loc.t('student.linkNewTeacher'),
          actionLabel: loc.t('student.linkNewTeacher'),
          onAction: () => _showLinkTeacherDialog(loc),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildTeacherCard(loc, state.linkedTeachers[index]),
        childCount: state.linkedTeachers.length,
      ),
    );
  }

  Widget _buildTeacherCard(AppLocalizations loc, UserProfile teacher) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: teacher.avatarUrl != null
                    ? NetworkImage(teacher.avatarUrl!)
                    : null,
                child: teacher.avatarUrl == null
                    ? Text(
                        teacher.name.isNotEmpty
                            ? teacher.name[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Name & info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            teacher.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (teacher.teacherCode != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.tertiary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              teacher.teacherCode!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.t('roles.teacher'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Unlink button
              IconButton(
                onPressed: () => _confirmUnlink(loc, teacher),
                icon: Icon(
                  Icons.link_off_rounded,
                  size: 20,
                  color: AppColors.lightDestructive.withValues(alpha: 0.7),
                ),
                tooltip: loc.t('student.unlink'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Incoming Requests Section ───

  Widget _buildIncomingRequestsTitle(AppLocalizations loc, TeachersState state) {
    final theme = Theme.of(context);

    if (state.incomingRequests.isEmpty && !state.isLoadingRequests) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              loc.t('student.incomingRequests'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (state.incomingRequests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightOcean,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.incomingRequests.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestsList(AppLocalizations loc, TeachersState state) {
    if (state.isLoadingRequests) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const LoadingShimmerCardBlock(),
        ),
      );
    }

    if (state.incomingRequests.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final request = state.incomingRequests[index];
          return _buildIncomingRequestCard(loc, request);
        },
        childCount: state.incomingRequests.length,
      ),
    );
  }

  Widget _buildIncomingRequestCard(
      AppLocalizations loc, TeacherStudentLink request) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = loc.isRTL ? 'ar' : 'en';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusGeometry,
          side: BorderSide(
            color: AppColors.lightOcean.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppColors.lightOcean.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.lightOcean,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.teacherId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd(locale).format(request.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Approve & Reject
              IconButton(
                onPressed: () => _approveRequest(request.id, loc),
                icon: Icon(Icons.check_circle_rounded,
                    color: AppColors.lightTealAccent, size: 24),
                tooltip: loc.t('common.accept'),
              ),
              IconButton(
                onPressed: () => _cancelRequest(request.id, loc),
                icon: Icon(Icons.cancel_rounded,
                    color: AppColors.lightDestructive, size: 24),
                tooltip: loc.t('common.reject'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pending Requests Section ───

  Widget _buildPendingRequestsTitle(AppLocalizations loc, TeachersState state) {

    // Show only if there are pending requests from the incoming list
    // (We reuse incoming requests since that's what the controller fetches)
    // In a real app there would be a separate list for sent requests
    return const SizedBox.shrink();
  }

  Widget _buildPendingRequestsList(AppLocalizations loc, TeachersState state) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // ─── Link Teacher Dialog ───

  void _showLinkTeacherDialog(AppLocalizations loc) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(teachersControllerProvider);

            return AlertDialog(
              title: Text(loc.t('student.linkNewTeacher')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: loc.t('student.teacherCodeLabel'),
                      hintText: loc.t('student.teacherCodePlaceholder'),
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('student.enterTeacherCode'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (state.actionError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightDestructive
                            .withValues(alpha: 0.08),
                        borderRadius: AppTheme.borderRadiusGeometry,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.lightDestructive),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.actionError!,
                              style: TextStyle(
                                color: AppColors.lightDestructive,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: state.isSendingRequest
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(loc.commonCancel),
                ),
                ElevatedButton(
                  onPressed: state.isSendingRequest
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) return;

                          final success = await ref
                              .read(teachersControllerProvider.notifier)
                              .sendLinkRequest(code);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.t('student.linkRequestSent'),
                                  ),
                                  backgroundColor: AppColors.lightTealAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: state.isSendingRequest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('student.sendRequest')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Confirm Unlink ───

  void _confirmUnlink(AppLocalizations loc, UserProfile teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('student.unlink')),
        content: Text(loc.t('student.unlinkConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(teachersControllerProvider.notifier)
                  .unlinkTeacher(teacher.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.t('student.unlinkSuccess')),
                    backgroundColor: AppColors.lightTealAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightDestructive,
              foregroundColor: AppColors.lightDestructiveForeground,
            ),
            child: Text(loc.t('student.unlink')),
          ),
        ],
      ),
    );
  }

  // ─── Approve Request ───

  Future<void> _approveRequest(String requestId, AppLocalizations loc) async {
    final success = await ref
        .read(teachersControllerProvider.notifier)
        .approveLinkRequest(requestId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('student.acceptSuccess')),
          backgroundColor: AppColors.lightTealAccent,
        ),
      );
    }
  }

  // ─── Cancel / Reject Request ───

  Future<void> _cancelRequest(String requestId, AppLocalizations loc) async {
    final success = await ref
        .read(teachersControllerProvider.notifier)
        .cancelLinkRequest(requestId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('student.rejectSuccess')),
        ),
      );
    }
  }
}

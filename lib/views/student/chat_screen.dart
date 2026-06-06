import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
// Chat Screen – Conversations List + Conversation Detail
// ────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Connect socket and fetch conversations on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).connectSocket();
      ref.read(chatControllerProvider.notifier).fetchConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    final q = _searchQuery.toLowerCase();
    return conversations.where((c) {
      final name = c.name?.toLowerCase() ?? '';
      final lastMsg = c.lastMessage?.content.toLowerCase() ?? '';
      return name.contains(q) || lastMsg.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(chatControllerProvider.notifier).fetchConversations(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Header + Search ───
          SliverToBoxAdapter(
            child: _buildHeader(chatState, loc, theme),
          ),

          // ─── Content ───
          if (chatState.isLoadingConversations &&
              chatState.conversations.isEmpty)
            SliverToBoxAdapter(child: _buildLoadingState())
          else if (chatState.error != null &&
              chatState.conversations.isEmpty)
            SliverToBoxAdapter(
              child: SectionErrorBoundary(
                message: chatState.error,
                onRetry: () => ref
                    .read(chatControllerProvider.notifier)
                    .fetchConversations(),
              ),
            )
          else if (chatState.conversations.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(loc),
            )
          else
            _buildConversationList(
                _filterConversations(chatState.conversations)),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeader(ChatState state, AppLocalizations loc, ThemeData theme) {
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
                  '${loc.t('chat.title')} (${state.conversations.length})',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // Socket status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isSocketConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isSocketConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isSocketConnected
                          ? loc.t('chat.online')
                          : loc.t('chat.offline'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: state.isSocketConnected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                LoadingShimmer.circle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer.textLine(width: 150, height: 14),
                      const SizedBox(height: 8),
                      LoadingShimmer.textLine(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState(AppLocalizations loc) {
    return EmptyState(
      icon: LucideIcons.messageCircle,
      title: loc.t('chat.noMessages'),
      description: loc.t('chat.startConversation'),
    );
  }

  // ─── Conversation List ───

  Widget _buildConversationList(List<Conversation> conversations) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ConversationCard(
            conversation: conversations[index],
            onTap: () => _openConversation(conversations[index]),
          ),
          childCount: conversations.length,
        ),
      ),
    );
  }

  // ─── Open Conversation Detail ───

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConversationDetailScreen(
          conversation: conversation,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Conversation Card
// ────────────────────────────────────────────────────────────

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);
    final loc = AppLocalizations.of(context);

    final displayName = conversation.name ?? loc.t('chat.title');
    final lastMsg = conversation.lastMessage;
    final timeAgo = lastMsg != null ? _formatTimeAgo(lastMsg.createdAt, loc) : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusGeometry,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(displayName, oceanColor, colorScheme),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg?.content ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge placeholder (would need unreadCount from model)
                        // For now, showing online indicator if group
                        if (conversation.type == 'group') ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.users,
                              size: 14, color: colorScheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
      String name, Color oceanColor, ColorScheme colorScheme) {
    if (conversation.avatarUrl != null && conversation.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(conversation.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: oceanColor.withValues(alpha: 0.15),
      child: Icon(
        conversation.type == 'group' ? LucideIcons.users : LucideIcons.user,
        size: 20,
        color: oceanColor,
      ),
    );
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
    return '${dt.day}/${dt.month}';
  }
}

// ────────────────────────────────────────────────────────────
// Conversation Detail Screen
// ────────────────────────────────────────────────────────────

class _ConversationDetailScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const _ConversationDetailScreen({required this.conversation});

  @override
  ConsumerState<_ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<_ConversationDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<ChatMessage>? _messageSub;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Fetch messages for this conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatControllerProvider.notifier)
          .fetchMessages(widget.conversation.id);

      // Listen for new messages to auto-scroll
      final socketSvc = ref.read(socketServiceProvider);
      _messageSub = socketSvc.onNewMessage().listen((message) {
        if (message.conversationId == widget.conversation.id && mounted) {
          _scrollToBottom();
        }
      });

      // Listen for typing events
      socketSvc.onTyping().listen((data) {
        if (data['conversationId'] == widget.conversation.id && mounted) {
          setState(() {
            _isTyping = data['isTyping'] == true;
          });
          // Auto-clear typing after 3s
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _isTyping = false);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSub?.cancel();
    // Leave the conversation room when exiting
    ref.read(chatControllerProvider.notifier).leaveActiveConversation();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);
    final oceanFg = AppColors.oceanForeground(brightness);
    final currentUserId =
        ref.read(supabaseServiceProvider).currentUser?.id ?? '';

    final displayName =
        widget.conversation.name ?? loc.t('chat.title');

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: oceanColor.withValues(alpha: 0.15),
                backgroundImage:
                    widget.conversation.avatarUrl != null &&
                            widget.conversation.avatarUrl!.isNotEmpty
                        ? NetworkImage(widget.conversation.avatarUrl!)
                        : null,
                child: widget.conversation.avatarUrl == null
                    ? Icon(
                        widget.conversation.type == 'group'
                            ? LucideIcons.users
                            : LucideIcons.user,
                        size: 16,
                        color: oceanColor,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: oceanFg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isTyping)
                      Text(
                        '...',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: oceanFg.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ─── Messages List ───
            Expanded(
              child: chatState.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : chatState.messages.isEmpty
                      ? EmptyState(
                          icon: LucideIcons.messageCircle,
                          title: loc.t('chat.noMessages'),
                          description: loc.t('chat.startConversation'),
                          compact: true,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chatState.messages[index];
                            final isMe = msg.senderId == currentUserId;
                            return _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              isGroup: widget.conversation.type == 'group',
                            );
                          },
                        ),
            ),

            // ─── Typing Indicator ───
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: Align(
                  alignment: loc.isRTL
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    '...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // ─── Error Banner ───
            if (chatState.error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.errorContainer,
                child: Text(
                  chatState.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),

            // ─── Message Input ───
            _MessageInput(
              controller: _messageController,
              onSend: _sendMessage,
              isSending: chatState.isSending,
              loc: loc,
              theme: theme,
              oceanColor: oceanColor,
              onAttachmentTap: _handleAttachment,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await ref
        .read(chatControllerProvider.notifier)
        .sendMessage(widget.conversation.id, content);

    _scrollToBottom();

    // Stop typing
    ref.read(socketServiceProvider).emitStopTyping(widget.conversation.id);
  }

  void _handleAttachment() {
    // Placeholder for file attachment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('chat.newMessage')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Message Bubble
// ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isGroup;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final oceanColor = AppColors.ocean(brightness);

    final alignment =
        isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe
        ? oceanColor
        : colorScheme.surfaceContainerHighest;
    final textColor =
        isMe ? AppColors.oceanForeground(brightness) : colorScheme.onSurface;

    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight:
                    isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Sender name for group chats
                if (isGroup && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderId,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: oceanColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // File attachment indicator
                if (message.messageType == 'file' &&
                    message.fileName != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileText,
                          size: 16, color: textColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.fileName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Message content
                Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 4),

                // Timestamp + read receipt
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead == true
                            ? LucideIcons.checkCheck
                            : LucideIcons.check,
                        size: 14,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Message Input Bar
// ────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool isSending;
  final AppLocalizations loc;
  final ThemeData theme;
  final Color oceanColor;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.loc,
    required this.theme,
    required this.oceanColor,
    required this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: onAttachmentTap,
              icon: Icon(LucideIcons.paperclip,
                  size: 22, color: theme.colorScheme.onSurfaceVariant),
              tooltip: loc.t('files.share'),
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: loc.t('chat.typeMessage'),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                onPressed: isSending ? null : onSend,
                backgroundColor: oceanColor,
                foregroundColor: AppColors.oceanForeground(theme.brightness),
                elevation: 0,
                shape: const CircleBorder(),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Chat State ───

class ChatState {
  final List<Conversation> conversations;
  final List<ChatMessage> messages;
  final String? activeConversationId;
  final bool isLoadingConversations;
  final bool isLoadingMessages;
  final bool isSending;
  final bool isSocketConnected;
  final String? error;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.activeConversationId,
    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.isSocketConnected = false,
    this.error,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    List<ChatMessage>? messages,
    String? activeConversationId,
    bool? isLoadingConversations,
    bool? isLoadingMessages,
    bool? isSending,
    bool? isSocketConnected,
    String? error,
    bool clearError = false,
    bool clearActiveConversation = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      activeConversationId: clearActiveConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Chat Controller ───

class ChatController extends StateNotifier<ChatState> {
  final SocketService _socketService;
  final SupabaseService _supabaseService;
  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatController(
    this._socketService,
    this._supabaseService,
  ) : super(const ChatState()) {
    _listenToSocketMessages();
  }

  void _listenToSocketMessages() {
    _messageSubscription = _socketService.onNewMessage().listen((message) {
      if (message.conversationId == state.activeConversationId) {
        state = state.copyWith(messages: [...state.messages, message]);
      }
    });
  }

  // ── Conversations ──

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoadingConversations: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('conversations')
          .select()
          .contains('participant_ids', [userId])
          .order('updated_at', ascending: false);

      final conversations = (data as List<dynamic>)
          .map((json) =>
              Conversation.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        conversations: conversations,
        isLoadingConversations: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingConversations: false,
        error: _friendlyError(e),
      );
    }
  }

  // ── Messages ──

  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(
      isLoadingMessages: true,
      clearError: true,
      activeConversationId: conversationId,
    );

    // Join the conversation room on socket
    _socketService.joinConversation(conversationId);

    try {
      final data = await _supabaseService.client
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(AppConstants.defaultPageSize * 2);

      final messages = (data as List<dynamic>)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(messages: messages, isLoadingMessages: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: _friendlyError(e),
      );
    }
  }

  // ── Send Message ──

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Insert message via Supabase
      await _supabaseService.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content.trim(),
        'message_type': 'text',
      });

      // Also emit via socket for real-time delivery
      _socketService.sendMessage(
        conversationId: conversationId,
        content: content.trim(),
      );

      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: _friendlyError(e),
      );
    }
  }

  // ── Socket Connection ──

  void connectSocket() {
    final userId = _supabaseService.currentUser?.id;
    final token = _supabaseService.currentSession?.accessToken;
    if (userId == null || token == null) return;

    _socketService.connect(userId: userId, token: token);
    state = state.copyWith(isSocketConnected: true);
  }

  void disconnectSocket() {
    _socketService.disconnect();
    state = state.copyWith(isSocketConnected: false);
  }

  void leaveActiveConversation() {
    if (state.activeConversationId != null) {
      _socketService.leaveConversation(state.activeConversationId!);
    }
    state = state.copyWith(clearActiveConversation: true, messages: []);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred with chat. Please try again.';
  }
}

// ─── Provider ───

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(
    ref.watch(socketServiceProvider),
    ref.watch(supabaseServiceProvider),
  );
});

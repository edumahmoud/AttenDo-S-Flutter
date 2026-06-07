import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_service.dart';

/// خدمة المحادثة الفورية المعتمدة على Supabase Realtime
/// كل الرسائل والتنبيهات وحالة الحضور تتم عبر Supabase Realtime Channels
/// لا يتم استخدام Socket.IO - الاتصال الفوري يعتمد كلياً على Supabase
class RealtimeChatService {
  final SupabaseClient _client;
  RealtimeChannel? _chatChannel;
  RealtimeChannel? _presenceChannel;
  bool _connected = false;
  String? _currentUserId;

  // Stream controllers for real-time events
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _userOnlineController =
      StreamController<String>.broadcast();
  final StreamController<String> _userOfflineController =
      StreamController<String>.broadcast();

  RealtimeChatService(this._client);

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  /// الاتصال بـ Supabase Realtime
  void connect({required String userId, required String token}) {
    if (_connected) return;
    _currentUserId = userId;

    try {
      // قناة الحضور (Presence) لتتبع المستخدمين المتصلين
      _presenceChannel = _client.channel('online-users');

      // عندما مستخدم يتصل
      _presenceChannel!.onPresenceJoin((payload) {
        for (final presence in payload.newPresences) {
          final uid = presence.payload['user_id'] as String?;
          if (uid != null && uid != _currentUserId) {
            if (!_userOnlineController.isClosed) {
              _userOnlineController.add(uid);
            }
          }
        }
      });

      // عندما مستخدم ينقطع
      _presenceChannel!.onPresenceLeave((payload) {
        for (final presence in payload.leftPresences) {
          final uid = presence.payload['user_id'] as String?;
          if (uid != null && uid != _currentUserId) {
            if (!_userOfflineController.isClosed) {
              _userOfflineController.add(uid);
            }
          }
        }
      });

      _presenceChannel!.subscribe((status, error) {});

      // تسجيل حضور المستخدم الحالي
      _presenceChannel!.track({
        'user_id': userId,
        'online_at': DateTime.now().toIso8601String(),
      });

      _connected = true;
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  /// قطع الاتصال من Supabase Realtime
  void disconnect() {
    _chatChannel?.unsubscribe();
    _presenceChannel?.untrack();
    _presenceChannel?.unsubscribe();
    _connected = false;
  }

  /// هل الاتصال نشط؟
  bool get isConnected => _connected;

  // ---------------------------------------------------------------------------
  // Conversation Management
  // ---------------------------------------------------------------------------

  /// الاشتراك في محادثة لاستقبال الرسائل الجديدة عبر Supabase Realtime
  void joinConversation(String conversationId) {
    // إلغاء اشتراك القناة القديمة
    _chatChannel?.unsubscribe();

    // إنشاء قناة Realtime للمحادثة
    _chatChannel = _client.channel('chat:$conversationId');

    _chatChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (PostgresChangePayload payload) {
        if (!_messageController.isClosed) {
          final newMessage = payload.newRecord;
          // لا نعيد بث الرسائل المرسلة من المستخدم الحالي
          if (newMessage['sender_id'] != _currentUserId) {
            _messageController.add(
              ChatMessage.fromJson(newMessage),
            );
          }
        }
      },
    )
        .subscribe((status, error) {});
  }

  /// إلغاء الاشتراك من محادثة
  void leaveConversation(String conversationId) {
    _chatChannel?.unsubscribe();
    _chatChannel = null;
  }

  // ---------------------------------------------------------------------------
  // Sending Messages
  // ---------------------------------------------------------------------------

  /// إرسال رسالة محادثة - تُحفظ في قاعدة البيانات وسيتم بثها تلقائياً عبر Realtime
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    if (_currentUserId == null) return;

    await _client.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': _currentUserId,
      'content': content.trim(),
      'message_type': 'text',
    });
  }

  // ---------------------------------------------------------------------------
  // Typing Indicators
  // ---------------------------------------------------------------------------

  /// بث حالة الكتابة عبر Presence
  void emitTyping(String conversationId) {
    _presenceChannel?.track({
      'user_id': _currentUserId,
      'typing_in': conversationId,
      'online_at': DateTime.now().toIso8601String(),
    });

    if (!_typingController.isClosed) {
      _typingController.add({
        'conversationId': conversationId,
        'userId': _currentUserId,
      });
    }
  }

  /// إيقاف حالة الكتابة
  void emitStopTyping(String conversationId) {
    _presenceChannel?.track({
      'user_id': _currentUserId,
      'typing_in': null,
      'online_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// استقبال الرسائل الجديدة
  Stream<ChatMessage> onNewMessage() => _messageController.stream;

  /// استقبال أحداث الكتابة
  Stream<Map<String, dynamic>> onTyping() => _typingController.stream;

  /// استقبال أحداث اتصال المستخدمين
  Stream<String> onUserOnline() => _userOnlineController.stream;

  /// استقبال أحداث انقطاع المستخدمين
  Stream<String> onUserOffline() => _userOfflineController.stream;

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// تنظيف الموارد
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _userOnlineController.close();
    _userOfflineController.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final realtimeChatServiceProvider = Provider<RealtimeChatService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final service = RealtimeChatService(client);
  ref.onDispose(() => service.dispose());
  return service;
});

/// استقبال الرسائل الجديدة
final chatMessagesProvider = StreamProvider<ChatMessage>((ref) {
  final chatService = ref.watch(realtimeChatServiceProvider);
  return chatService.onNewMessage();
});

/// استقبال أحداث الكتابة
final typingEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final chatService = ref.watch(realtimeChatServiceProvider);
  return chatService.onTyping();
});

/// استقبال أحداث اتصال المستخدمين
final userOnlineProvider = StreamProvider<String>((ref) {
  final chatService = ref.watch(realtimeChatServiceProvider);
  return chatService.onUserOnline();
});

/// استقبال أحداث انقطاع المستخدمين
final userOfflineProvider = StreamProvider<String>((ref) {
  final chatService = ref.watch(realtimeChatServiceProvider);
  return chatService.onUserOffline();
});

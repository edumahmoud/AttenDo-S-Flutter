import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/constants/app_constants.dart';
import '../models/models.dart';

class SocketService {
  io.Socket? _socket;
  bool _connected = false;

  // Stream controllers for real-time events
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _userOnlineController =
      StreamController<String>.broadcast();
  final StreamController<String> _userOfflineController =
      StreamController<String>.broadcast();

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  /// Connect to the Socket.IO server with the given user ID and auth token.
  void connect({required String userId, required String token}) {
    if (_connected && _socket != null) return;

    try {
      _socket = io.io(
        AppConstants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({
              'Authorization': 'Bearer $token',
            })
            .build(),
      );

      _socket!.on('connect', (_) {
        _connected = true;
        _socket!.emit('user:online', {'userId': userId});
      });

      _socket!.on('disconnect', (_) {
        _connected = false;
      });

      _socket!.on('connect_error', (data) {
        _connected = false;
      });

      // Bind real-time event listeners
      _socket!.on('message:new', (data) {
        if (!_messageController.isClosed) {
          _messageController.add(
            ChatMessage.fromJson(data as Map<String, dynamic>),
          );
        }
      });

      _socket!.on('typing', (data) {
        if (!_typingController.isClosed) {
          _typingController.add(data as Map<String, dynamic>);
        }
      });

      _socket!.on('user:online', (data) {
        if (!_userOnlineController.isClosed) {
          final userId = (data as Map<String, dynamic>)['userId'] as String?;
          if (userId != null) _userOnlineController.add(userId);
        }
      });

      _socket!.on('user:offline', (data) {
        if (!_userOfflineController.isClosed) {
          final userId = (data as Map<String, dynamic>)['userId'] as String?;
          if (userId != null) _userOfflineController.add(userId);
        }
      });

      _socket!.connect();
    } catch (e) {
      rethrow;
    }
  }

  /// Disconnect from the Socket.IO server and clean up.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  /// Whether the socket is currently connected.
  bool get isConnected => _connected;

  // ---------------------------------------------------------------------------
  // Conversation Management
  // ---------------------------------------------------------------------------

  /// Join a conversation room so messages are received.
  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  /// Leave a conversation room.
  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  // ---------------------------------------------------------------------------
  // Sending Messages
  // ---------------------------------------------------------------------------

  /// Send a chat message to a conversation.
  void sendMessage({
    required String conversationId,
    required String content,
  }) {
    _socket?.emit('message:send', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  // ---------------------------------------------------------------------------
  // Typing Indicators
  // ---------------------------------------------------------------------------

  /// Emit a typing event for a conversation.
  void emitTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  /// Emit a stop-typing event for a conversation.
  void emitStopTyping(String conversationId) {
    _socket?.emit('stop:typing', {'conversationId': conversationId});
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Stream of new incoming chat messages.
  Stream<ChatMessage> onNewMessage() => _messageController.stream;

  /// Stream of typing events (maps with conversationId, userId, etc.).
  Stream<Map<String, dynamic>> onTyping() => _typingController.stream;

  /// Stream of user-online events (emits userId).
  Stream<String> onUserOnline() => _userOnlineController.stream;

  /// Stream of user-offline events (emits userId).
  Stream<String> onUserOffline() => _userOfflineController.stream;

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Dispose all stream controllers. Call when the service is no longer needed.
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

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider that exposes the new-message stream for the current socket.
final chatMessagesProvider = StreamProvider<ChatMessage>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onNewMessage();
});

/// Provider that exposes typing events.
final typingEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onTyping();
});

/// Provider that exposes user-online events.
final userOnlineProvider = StreamProvider<String>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onUserOnline();
});

/// Provider that exposes user-offline events.
final userOfflineProvider = StreamProvider<String>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onUserOffline();
});

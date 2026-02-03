import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/connectivity_service.dart';
import '../services/exceptions/api_exception.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

/// Provider for chat state management
class ChatProvider extends ChangeNotifier {
  final OpenAiService _openAi;
  final StorageService _storage;
  final ConnectivityService _connectivity;

  List<ChatSession> _sessions = [];
  ChatSession _currentSession = ChatSession.empty();
  bool _isLoading = false;
  String? _error;
  StreamSubscription<String>? _streamSubscription;

  ChatProvider({
    required OpenAiService openAi,
    required StorageService storage,
    required ConnectivityService connectivity,
  })  : _openAi = openAi,
        _storage = storage,
        _connectivity = connectivity;

  // Getters
  List<ChatSession> get sessions => _sessions;
  ChatSession get currentSession => _currentSession;
  List<ChatMessage> get messages => _currentSession.messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessages => _currentSession.isNotEmpty;
  bool get isStreaming =>
      messages.isNotEmpty && messages.last.status == MessageStatus.streaming;

  /// Initialize provider and load history
  Future<void> init() async {
    _sessions = await _storage.loadChatSessions();
    if (_sessions.isNotEmpty) {
      _currentSession = _sessions.first;
    }
    notifyListeners();
  }

  /// Start a new chat session
  void newChat() {
    _currentSession = ChatSession.empty();
    _error = null;
    notifyListeners();
  }

  /// Select a session by ID
  void selectSession(String sessionId) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => ChatSession.empty(),
    );
    _currentSession = session;
    _error = null;
    notifyListeners();
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession.id == sessionId) {
      _currentSession =
          _sessions.isNotEmpty ? _sessions.first : ChatSession.empty();
    }
    await _saveHistory();
    notifyListeners();
  }

  /// Send a message and stream the response
  Future<void> sendMessage(String content, {String? model}) async {
    if (content.trim().isEmpty) return;

    if (!_connectivity.isConnected) {
      _error = 'No internet connection';
      notifyListeners();
      return;
    }

    _error = null;

    // Add user message
    final userMessage = ChatMessage.user(content.trim());
    _currentSession = _currentSession.addMessage(userMessage);
    notifyListeners();

    // Add streaming placeholder
    final streamingMessage = ChatMessage.streaming();
    _currentSession = _currentSession.addMessage(streamingMessage);
    _isLoading = true;
    notifyListeners();

    try {
      String responseContent = '';

      final stream = _openAi.sendChatMessage(
        messages: _currentSession.messages
            .where((m) => m.status == MessageStatus.completed)
            .toList(),
        model: model ?? _storage.getChatModel(),
      );

      await for (final delta in stream) {
        responseContent += delta;
        _currentSession = _currentSession.updateLastMessage(
          streamingMessage.copyWith(
            content: responseContent,
            status: MessageStatus.streaming,
          ),
        );
        notifyListeners();
      }

      // Mark as completed
      _currentSession = _currentSession.updateLastMessage(
        streamingMessage.copyWith(
          content: responseContent,
          status: MessageStatus.completed,
        ),
      );

      // Save session
      await _saveCurrentSession();
    } on AppException catch (e) {
      _error = e.message;
      _currentSession = _currentSession.updateLastMessage(
        ChatMessage.error(e.message),
      );
    } catch (e) {
      _error = 'An unexpected error occurred';
      _currentSession = _currentSession.updateLastMessage(
        ChatMessage.error('An unexpected error occurred'),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel current streaming response
  void cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (isStreaming) {
      final lastMessage = messages.last;
      if (lastMessage.content.isEmpty) {
        // Remove empty streaming message
        _currentSession = _currentSession.removeMessage(lastMessage.id);
      } else {
        // Mark partial response as completed
        _currentSession = _currentSession.updateLastMessage(
          lastMessage.copyWith(status: MessageStatus.completed),
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Retry the last failed message
  Future<void> retryLastMessage({String? model}) async {
    if (messages.isEmpty) return;

    final lastMessage = messages.last;
    if (!lastMessage.hasError) return;

    // Remove error message
    _currentSession = _currentSession.removeMessage(lastMessage.id);

    // Find the last user message
    final lastUserMessage = messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage.user(''),
    );

    if (lastUserMessage.content.isNotEmpty) {
      // Remove user message and resend
      _currentSession = _currentSession.removeMessage(lastUserMessage.id);
      notifyListeners();
      await sendMessage(lastUserMessage.content, model: model);
    }
  }

  /// Delete a specific message
  void deleteMessage(String messageId) {
    _currentSession = _currentSession.removeMessage(messageId);
    _saveCurrentSession();
    notifyListeners();
  }

  /// Clear current chat
  void clearChat() {
    _currentSession = _currentSession.clear();
    _error = null;
    notifyListeners();
  }

  /// Clear all chat history
  Future<void> clearAllHistory() async {
    _sessions.clear();
    _currentSession = ChatSession.empty();
    await _storage.saveChatSessions([]);
    notifyListeners();
  }

  /// Save current session to history
  Future<void> _saveCurrentSession() async {
    if (_currentSession.isEmpty) return;

    // Update or add session
    final existingIndex = _sessions.indexWhere(
      (s) => s.id == _currentSession.id,
    );

    if (existingIndex >= 0) {
      _sessions[existingIndex] = _currentSession;
    } else {
      _sessions.insert(0, _currentSession);
    }

    // Limit history size
    if (_sessions.length > AppConstants.maxChatHistorySessions) {
      _sessions = _sessions.take(AppConstants.maxChatHistorySessions).toList();
    }

    await _saveHistory();
  }

  /// Save all sessions to storage
  Future<void> _saveHistory() async {
    await _storage.saveChatSessions(_sessions);
  }

  /// Copy message content
  String getMessageContent(String messageId) {
    final message = messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => ChatMessage.user(''),
    );
    return message.content;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

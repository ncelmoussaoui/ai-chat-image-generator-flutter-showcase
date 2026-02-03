import 'package:uuid/uuid.dart';
import 'chat_message.dart';

/// Represents a chat session containing multiple messages
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? 'New Chat',
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a new empty session
  factory ChatSession.empty() {
    return ChatSession();
  }

  /// Get the last message in the session
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get a title based on the first user message
  String get displayTitle {
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage.user('New Chat'),
    );
    final content = firstUserMessage.content;
    if (content.length > 50) {
      return '${content.substring(0, 50)}...';
    }
    return content.isNotEmpty ? content : 'New Chat';
  }

  /// Copy with new values
  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add a message to the session
  ChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Update the last message
  ChatSession updateLastMessage(ChatMessage message) {
    if (messages.isEmpty) {
      return addMessage(message);
    }
    final updatedMessages = [...messages];
    updatedMessages[updatedMessages.length - 1] = message;
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a message by ID
  ChatSession removeMessage(String messageId) {
    return copyWith(
      messages: messages.where((m) => m.id != messageId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Clear all messages
  ChatSession clear() {
    return copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String?,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Check if the session is empty
  bool get isEmpty => messages.isEmpty;

  /// Check if the session has messages
  bool get isNotEmpty => messages.isNotEmpty;

  /// Get the message count
  int get messageCount => messages.length;
}

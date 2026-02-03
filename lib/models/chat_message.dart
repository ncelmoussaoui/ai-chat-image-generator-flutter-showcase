import 'package:uuid/uuid.dart';

/// Role of the message sender
enum MessageRole {
  user,
  assistant,
  system,
}

/// Status of the message
enum MessageStatus {
  sending,
  streaming,
  completed,
  error,
}

/// Represents a single chat message
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final DateTime timestamp;
  final String? errorMessage;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.status = MessageStatus.completed,
    DateTime? timestamp,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Create a user message
  factory ChatMessage.user(String content) {
    return ChatMessage(
      role: MessageRole.user,
      content: content,
      status: MessageStatus.completed,
    );
  }

  /// Create an assistant message
  factory ChatMessage.assistant(String content, {MessageStatus? status}) {
    return ChatMessage(
      role: MessageRole.assistant,
      content: content,
      status: status ?? MessageStatus.completed,
    );
  }

  /// Create a streaming assistant message
  factory ChatMessage.streaming() {
    return ChatMessage(
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.streaming,
    );
  }

  /// Create an error message
  factory ChatMessage.error(String errorMessage) {
    return ChatMessage(
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Copy with new values
  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    MessageStatus? status,
    DateTime? timestamp,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.completed,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get hasError => status == MessageStatus.error;
  bool get isCompleted => status == MessageStatus.completed;
}

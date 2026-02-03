import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_image_generator/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('creates user message correctly', () {
      final message = ChatMessage.user('Hello');

      expect(message.role, MessageRole.user);
      expect(message.content, 'Hello');
      expect(message.status, MessageStatus.completed);
      expect(message.isUser, true);
      expect(message.isAssistant, false);
    });

    test('creates assistant message correctly', () {
      final message = ChatMessage.assistant('Hi there!');

      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Hi there!');
      expect(message.status, MessageStatus.completed);
      expect(message.isAssistant, true);
      expect(message.isUser, false);
    });

    test('creates streaming message correctly', () {
      final message = ChatMessage.streaming();

      expect(message.role, MessageRole.assistant);
      expect(message.content, '');
      expect(message.status, MessageStatus.streaming);
      expect(message.isStreaming, true);
    });

    test('creates error message correctly', () {
      final message = ChatMessage.error('Network error');

      expect(message.role, MessageRole.assistant);
      expect(message.status, MessageStatus.error);
      expect(message.hasError, true);
      expect(message.errorMessage, 'Network error');
    });

    test('copyWith updates values correctly', () {
      final original = ChatMessage.user('Original');
      final copied = original.copyWith(content: 'Updated');

      expect(copied.content, 'Updated');
      expect(copied.id, original.id);
      expect(copied.role, original.role);
    });

    test('serializes to JSON correctly', () {
      final message = ChatMessage.user('Test message');
      final json = message.toJson();

      expect(json['role'], 'user');
      expect(json['content'], 'Test message');
      expect(json['status'], 'completed');
      expect(json['id'], isNotEmpty);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'role': 'assistant',
        'content': 'Test response',
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
        'errorMessage': null,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 'test-id');
      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Test response');
      expect(message.status, MessageStatus.completed);
    });

    test('generates unique IDs', () {
      final message1 = ChatMessage.user('First');
      final message2 = ChatMessage.user('Second');

      expect(message1.id, isNot(message2.id));
    });
  });
}

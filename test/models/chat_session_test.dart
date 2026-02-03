import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_image_generator/models/chat_message.dart';
import 'package:ai_chat_image_generator/models/chat_session.dart';

void main() {
  group('ChatSession', () {
    test('creates empty session correctly', () {
      final session = ChatSession.empty();

      expect(session.isEmpty, true);
      expect(session.isNotEmpty, false);
      expect(session.messageCount, 0);
      expect(session.lastMessage, null);
    });

    test('adds message correctly', () {
      final session = ChatSession.empty();
      final message = ChatMessage.user('Hello');

      final updated = session.addMessage(message);

      expect(updated.messageCount, 1);
      expect(updated.lastMessage?.content, 'Hello');
      expect(updated.isNotEmpty, true);
    });

    test('updates last message correctly', () {
      var session = ChatSession.empty();
      session = session.addMessage(ChatMessage.streaming());

      final updated = session.updateLastMessage(
        ChatMessage.assistant('Response', status: MessageStatus.completed),
      );

      expect(updated.lastMessage?.content, 'Response');
      expect(updated.lastMessage?.status, MessageStatus.completed);
    });

    test('removes message correctly', () {
      var session = ChatSession.empty();
      final message = ChatMessage.user('To remove');
      session = session.addMessage(message);

      final updated = session.removeMessage(message.id);

      expect(updated.isEmpty, true);
    });

    test('clears all messages', () {
      var session = ChatSession.empty();
      session = session.addMessage(ChatMessage.user('First'));
      session = session.addMessage(ChatMessage.assistant('Second'));

      final cleared = session.clear();

      expect(cleared.isEmpty, true);
      expect(cleared.id, session.id);
    });

    test('displayTitle uses first user message', () {
      var session = ChatSession.empty();
      session = session.addMessage(ChatMessage.user('My question here'));

      expect(session.displayTitle, 'My question here');
    });

    test('displayTitle truncates long messages', () {
      var session = ChatSession.empty();
      final longMessage = 'A' * 100;
      session = session.addMessage(ChatMessage.user(longMessage));

      expect(session.displayTitle.length, 53); // 50 chars + "..."
      expect(session.displayTitle.endsWith('...'), true);
    });

    test('serializes to JSON correctly', () {
      var session = ChatSession.empty();
      session = session.addMessage(ChatMessage.user('Test'));

      final json = session.toJson();

      expect(json['id'], isNotEmpty);
      expect(json['messages'], isA<List>());
      expect((json['messages'] as List).length, 1);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'session-id',
        'title': 'Test Session',
        'messages': [
          {
            'id': 'msg-id',
            'role': 'user',
            'content': 'Hello',
            'status': 'completed',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final session = ChatSession.fromJson(json);

      expect(session.id, 'session-id');
      expect(session.messageCount, 1);
      expect(session.messages.first.content, 'Hello');
    });

    test('preserves session ID across updates', () {
      final session = ChatSession.empty();
      final originalId = session.id;

      final updated = session.addMessage(ChatMessage.user('Test'));

      expect(updated.id, originalId);
    });
  });
}

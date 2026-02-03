import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_image_generator/models/image_result.dart';

void main() {
  group('ImageResult', () {
    test('creates completed result correctly', () {
      final result = ImageResult(
        prompt: 'A cat in space',
        imageUrl: 'https://example.com/image.png',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      expect(result.prompt, 'A cat in space');
      expect(result.imageUrl, 'https://example.com/image.png');
      expect(result.model, 'dall-e-3');
      expect(result.size, '1024x1024');
      expect(result.isCompleted, true);
      expect(result.hasImageData, true);
    });

    test('creates generating result correctly', () {
      final result = ImageResult.generating(
        prompt: 'Test prompt',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      expect(result.isGenerating, true);
      expect(result.isCompleted, false);
      expect(result.hasImageData, false);
    });

    test('creates error result correctly', () {
      final result = ImageResult.error(
        prompt: 'Test prompt',
        model: 'dall-e-3',
        size: '1024x1024',
        errorMessage: 'Content policy violation',
      );

      expect(result.hasError, true);
      expect(result.errorMessage, 'Content policy violation');
      expect(result.isCompleted, false);
    });

    test('copyWith updates values correctly', () {
      final original = ImageResult.generating(
        prompt: 'Test',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      final completed = original.copyWith(
        imageUrl: 'https://example.com/image.png',
        status: ImageGenerationStatus.completed,
      );

      expect(completed.imageUrl, 'https://example.com/image.png');
      expect(completed.isCompleted, true);
      expect(completed.prompt, 'Test');
      expect(completed.id, original.id);
    });

    test('displaySource prefers localPath over URL', () {
      final result = ImageResult(
        prompt: 'Test',
        imageUrl: 'https://example.com/image.png',
        localPath: '/path/to/local.png',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      expect(result.displaySource, '/path/to/local.png');
    });

    test('displaySource falls back to URL', () {
      final result = ImageResult(
        prompt: 'Test',
        imageUrl: 'https://example.com/image.png',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      expect(result.displaySource, 'https://example.com/image.png');
    });

    test('serializes to JSON correctly', () {
      final result = ImageResult(
        prompt: 'Test prompt',
        imageUrl: 'https://example.com/image.png',
        revisedPrompt: 'Revised prompt',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      final json = result.toJson();

      expect(json['prompt'], 'Test prompt');
      expect(json['imageUrl'], 'https://example.com/image.png');
      expect(json['revisedPrompt'], 'Revised prompt');
      expect(json['model'], 'dall-e-3');
      expect(json['size'], '1024x1024');
      expect(json['status'], 'completed');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'image-id',
        'prompt': 'Test prompt',
        'imageUrl': 'https://example.com/image.png',
        'model': 'dall-e-3',
        'size': '1024x1024',
        'status': 'completed',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final result = ImageResult.fromJson(json);

      expect(result.id, 'image-id');
      expect(result.prompt, 'Test prompt');
      expect(result.imageUrl, 'https://example.com/image.png');
      expect(result.isCompleted, true);
    });

    test('generates unique IDs', () {
      final result1 = ImageResult(
        prompt: 'First',
        model: 'dall-e-3',
        size: '1024x1024',
      );
      final result2 = ImageResult(
        prompt: 'Second',
        model: 'dall-e-3',
        size: '1024x1024',
      );

      expect(result1.id, isNot(result2.id));
    });
  });
}

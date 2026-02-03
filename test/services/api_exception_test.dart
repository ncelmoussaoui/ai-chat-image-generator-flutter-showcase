import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_image_generator/services/exceptions/api_exception.dart';

void main() {
  group('API Exceptions', () {
    test('NetworkException has correct defaults', () {
      const exception = NetworkException();

      expect(exception.message, 'No internet connection');
      expect(exception.toString(), 'No internet connection');
    });

    test('AuthenticationException has correct defaults', () {
      const exception = AuthenticationException();

      expect(exception.message, 'Invalid API key');
      expect(exception.statusCode, 401);
    });

    test('RateLimitException provides retry message', () {
      const exception = RateLimitException(
        retryAfter: Duration(seconds: 30),
      );

      expect(exception.retryMessage, 'Please try again in 30 seconds');
    });

    test('RateLimitException handles null retryAfter', () {
      const exception = RateLimitException();

      expect(exception.retryMessage, 'Please try again later');
    });

    test('ContentFilterException has correct defaults', () {
      const exception = ContentFilterException();

      expect(exception.message, 'Content was flagged by safety filters');
      expect(exception.statusCode, 400);
    });

    test('ServerException can have custom message', () {
      const exception = ServerException(
        message: 'Custom server error',
        statusCode: 503,
      );

      expect(exception.message, 'Custom server error');
      expect(exception.statusCode, 503);
    });

    test('parseApiError returns AuthenticationException for 401', () {
      final exception = parseApiError(401, {
        'error': {'message': 'Invalid key'},
      });

      expect(exception, isA<AuthenticationException>());
      expect(exception.details, 'Invalid key');
    });

    test('parseApiError returns RateLimitException for 429', () {
      final exception = parseApiError(429, {
        'error': {'message': 'Rate limit exceeded'},
      });

      expect(exception, isA<RateLimitException>());
    });

    test('parseApiError returns ContentFilterException for content policy', () {
      final exception = parseApiError(400, {
        'error': {
          'message': 'Your request violated content policy',
          'type': 'content_policy_violation',
        },
      });

      expect(exception, isA<ContentFilterException>());
    });

    test('parseApiError returns BadRequestException for 400', () {
      final exception = parseApiError(400, {
        'error': {'message': 'Invalid parameters'},
      });

      expect(exception, isA<BadRequestException>());
    });

    test('parseApiError returns QuotaExceededException for 402', () {
      final exception = parseApiError(402, {
        'error': {'message': 'Quota exceeded'},
      });

      expect(exception, isA<QuotaExceededException>());
    });

    test('parseApiError returns ServerException for 5xx', () {
      for (final statusCode in [500, 502, 503, 504]) {
        final exception = parseApiError(statusCode, {
          'error': {'message': 'Server error'},
        });

        expect(exception, isA<ServerException>());
        expect(exception.statusCode, statusCode);
      }
    });

    test('parseApiError handles null response data', () {
      final exception = parseApiError(500, null);

      expect(exception, isA<ServerException>());
    });

    test('parseApiError handles missing error message', () {
      final exception = parseApiError(401, {});

      expect(exception, isA<AuthenticationException>());
    });
  });
}

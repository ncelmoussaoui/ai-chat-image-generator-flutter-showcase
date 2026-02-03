/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;

  const AppException({
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Exception thrown when there is no internet connection
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.details,
  });
}

/// Exception thrown when API authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Invalid API key',
    super.details,
    super.statusCode = 401,
  });
}

/// Exception thrown when rate limit is exceeded
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException({
    super.message = 'Rate limit exceeded',
    super.details,
    super.statusCode = 429,
    this.retryAfter,
  });

  String get retryMessage {
    if (retryAfter != null) {
      return 'Please try again in ${retryAfter!.inSeconds} seconds';
    }
    return 'Please try again later';
  }
}

/// Exception thrown when content violates policy
class ContentFilterException extends AppException {
  const ContentFilterException({
    super.message = 'Content was flagged by safety filters',
    super.details,
    super.statusCode = 400,
  });
}

/// Exception thrown for server errors (5xx)
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred',
    super.details,
    super.statusCode,
  });
}

/// Exception thrown when request is invalid
class BadRequestException extends AppException {
  const BadRequestException({
    super.message = 'Invalid request',
    super.details,
    super.statusCode = 400,
  });
}

/// Exception thrown for quota exceeded
class QuotaExceededException extends AppException {
  const QuotaExceededException({
    super.message = 'API quota exceeded',
    super.details,
    super.statusCode = 402,
  });
}

/// Exception thrown for timeout
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.details,
  });
}

/// Exception thrown for storage errors
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage error occurred',
    super.details,
  });
}

/// Parse API error response and return appropriate exception
AppException parseApiError(int? statusCode, dynamic responseData) {
  final message = responseData?['error']?['message'] as String?;
  final errorType = responseData?['error']?['type'] as String?;

  switch (statusCode) {
    case 401:
      return AuthenticationException(
        details: message ?? 'Invalid or missing API key',
      );
    case 402:
      return QuotaExceededException(
        details: message ?? 'Your API quota has been exceeded',
      );
    case 429:
      return RateLimitException(
        details: message ?? 'Too many requests',
      );
    case 400:
      if (errorType == 'content_policy_violation' ||
          message?.contains('content policy') == true) {
        return ContentFilterException(
          details: message ?? 'Your request violated content policy',
        );
      }
      return BadRequestException(
        details: message ?? 'Invalid request parameters',
      );
    case 500:
    case 502:
    case 503:
    case 504:
      return ServerException(
        statusCode: statusCode,
        details: message ?? 'OpenAI server error. Please try again.',
      );
    default:
      return ServerException(
        statusCode: statusCode,
        message: 'Unexpected error occurred',
        details: message,
      );
  }
}

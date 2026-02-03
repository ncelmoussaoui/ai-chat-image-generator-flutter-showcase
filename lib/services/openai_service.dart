import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/constants.dart';
import '../models/chat_message.dart';
import 'exceptions/api_exception.dart';

/// Service for OpenAI API interactions
class OpenAiService {
  final Dio _dio;
  String? _apiKey;
  String _baseUrl = AppConstants.openAiBaseUrl;
  ApiMode _apiMode = ApiMode.byok;

  OpenAiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = AppConstants.apiTimeout;
    _dio.options.receiveTimeout = AppConstants.streamTimeout;
  }

  /// Configure the service with API settings
  void configure({
    String? apiKey,
    String? baseUrl,
    ApiMode? apiMode,
  }) {
    if (apiKey != null) _apiKey = apiKey;
    if (baseUrl != null) _baseUrl = baseUrl;
    if (apiMode != null) _apiMode = apiMode;
  }

  /// Get headers for API requests
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_apiMode == ApiMode.byok && _apiKey != null) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    return headers;
  }

  /// Check if the service is configured
  bool get isConfigured {
    if (_apiMode == ApiMode.byok) {
      return _apiKey != null && _apiKey!.isNotEmpty;
    }
    return _baseUrl.isNotEmpty;
  }

  /// Validate API key by making a test request
  Future<bool> validateApiKey() async {
    if (!isConfigured) return false;

    try {
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(headers: _headers),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthenticationException();
      }
      return false;
    }
  }

  /// Send a chat message and stream the response
  Stream<String> sendChatMessage({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
  }) async* {
    if (!isConfigured) {
      throw const AuthenticationException(
        message: 'API not configured',
        details: 'Please configure your API key or server URL',
      );
    }

    final inputMessages = messages
        .where((m) => m.role != MessageRole.system || messages.indexOf(m) == 0)
        .map((m) => {
              'role': m.role.name,
              'content': m.content,
            })
        .toList();

    // Standard OpenAI request format uses 'messages' and 'max_tokens'
    final requestBody = {
      'model': model ?? AppConstants.defaultChatModel,
      'messages': inputMessages,
      'stream': true,
    };

    if (maxTokens != null) {
      requestBody['max_tokens'] = maxTokens;
    }

    try {
      final response = await _dio.post<ResponseBody>(
        '$_baseUrl${AppConstants.responsesEndpoint}',
        data: jsonEncode(requestBody),
        options: Options(
          headers: _headers,
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        throw const ServerException(
          message: 'No response stream received',
        );
      }

      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = _extractDelta(json);
              if (delta != null && delta.isNotEmpty) {
                yield delta;
              }
            } catch (_) {
              // Skip malformed JSON lines
            }
          }
        }
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Extract delta content from streaming response
  String? _extractDelta(Map<String, dynamic> json) {
    // Standard OpenAI chat completions format
    final choices = json['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final choice = choices[0] as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;
      if (delta != null && delta.containsKey('content')) {
        return delta['content'] as String?;
      }
    }

    // Fallback for custom server formats (like proxy servers)
    if (json.containsKey('type') && json['type'] == 'response.output_text.delta') {
      return json['delta'] as String?;
    }

    return null;
  }

  /// Generate an image
  Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String? model,
    String? size,
    int n = 1,
  }) async {
    if (!isConfigured) {
      throw const AuthenticationException(
        message: 'API not configured',
        details: 'Please configure your API key or server URL',
      );
    }

    final requestBody = {
      'model': model ?? AppConstants.defaultImageModel,
      'prompt': prompt,
      'n': n,
      'size': size ?? AppConstants.defaultImageSize,
    };

    try {
      final response = await _dio.post(
        '$_baseUrl${AppConstants.imagesEndpoint}',
        data: jsonEncode(requestBody),
        options: Options(headers: _headers),
      );

      final data = response.data as Map<String, dynamic>;
      final images = data['data'] as List<dynamic>;

      if (images.isEmpty) {
        throw const ServerException(
          message: 'No image generated',
        );
      }

      final image = images[0] as Map<String, dynamic>;
      return {
        'url': image['url'] as String?,
        'b64_json': image['b64_json'] as String?,
        'revised_prompt': image['revised_prompt'] as String?,
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Download an image from URL and save locally
  Future<String> downloadImage(String url, String savePath) async {
    try {
      final response = await _dio.download(url, savePath);
      if (response.statusCode == 200) {
        return savePath;
      }
      throw const ServerException(
        message: 'Failed to download image',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Save base64 image data to file
  Future<String> saveBase64Image(String base64Data, String savePath) async {
    try {
      final bytes = base64Decode(base64Data);
      final file = File(savePath);
      await file.writeAsBytes(bytes);
      return savePath;
    } catch (e) {
      throw StorageException(
        message: 'Failed to save image',
        details: e.toString(),
      );
    }
  }

  /// Handle Dio errors and convert to app exceptions
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return parseApiError(
          error.response?.statusCode,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return const ServerException(message: 'Request cancelled');

      default:
        return ServerException(
          message: 'Unexpected error',
          details: error.message,
        );
    }
  }
}

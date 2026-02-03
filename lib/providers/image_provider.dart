import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/image_result.dart';
import '../services/connectivity_service.dart';
import '../services/exceptions/api_exception.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

/// Provider for image generation state management
class ImageGeneratorProvider extends ChangeNotifier {
  final OpenAiService _openAi;
  final StorageService _storage;
  final ConnectivityService _connectivity;

  List<ImageResult> _history = [];
  ImageResult? _currentGeneration;
  bool _isGenerating = false;
  String? _error;
  String _selectedSize = AppConstants.defaultImageSize;

  ImageGeneratorProvider({
    required OpenAiService openAi,
    required StorageService storage,
    required ConnectivityService connectivity,
  })  : _openAi = openAi,
        _storage = storage,
        _connectivity = connectivity;

  // Getters
  List<ImageResult> get history => _history;
  ImageResult? get currentGeneration => _currentGeneration;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String get selectedSize => _selectedSize;
  bool get hasHistory => _history.isNotEmpty;

  /// Initialize provider and load history
  Future<void> init() async {
    _history = await _storage.loadImageHistory();
    notifyListeners();
  }

  /// Set image size
  void setSize(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  /// Generate an image from prompt
  Future<void> generateImage(String prompt, {String? model}) async {
    if (prompt.trim().isEmpty) return;

    if (!_connectivity.isConnected) {
      _error = 'No internet connection';
      notifyListeners();
      return;
    }

    _error = null;
    _isGenerating = true;

    _currentGeneration = ImageResult.generating(
      prompt: prompt.trim(),
      model: model ?? _storage.getImageModel(),
      size: _selectedSize,
    );
    notifyListeners();

    try {
      final result = await _openAi.generateImage(
        prompt: prompt.trim(),
        model: model ?? _storage.getImageModel(),
        size: _selectedSize,
      );

      String? localPath;
      final imageUrl = result['url'] as String?;
      final base64Data = result['b64_json'] as String?;

      // Save image locally
      if (imageUrl != null || base64Data != null) {
        final imagesDir = await _storage.getImagesDirectory();
        final fileName = '${const Uuid().v4()}.png';
        final savePath = '$imagesDir/$fileName';

        if (base64Data != null) {
          localPath = await _openAi.saveBase64Image(base64Data, savePath);
        } else if (imageUrl != null) {
          localPath = await _openAi.downloadImage(imageUrl, savePath);
        }
      }

      _currentGeneration = _currentGeneration!.copyWith(
        imageUrl: imageUrl,
        localPath: localPath,
        revisedPrompt: result['revised_prompt'] as String?,
        status: ImageGenerationStatus.completed,
      );

      // Add to history
      _history.insert(0, _currentGeneration!);

      // Limit history size
      if (_history.length > AppConstants.maxImageHistory) {
        final removed = _history.removeLast();
        // Delete old image file
        if (removed.localPath != null) {
          try {
            await File(removed.localPath!).delete();
          } catch (_) {}
        }
      }

      await _saveHistory();
    } on AppException catch (e) {
      _error = e.message;
      _currentGeneration = ImageResult.error(
        prompt: prompt.trim(),
        model: model ?? _storage.getImageModel(),
        size: _selectedSize,
        errorMessage: e.message,
      );
    } catch (e) {
      _error = 'An unexpected error occurred';
      _currentGeneration = ImageResult.error(
        prompt: prompt.trim(),
        model: model ?? _storage.getImageModel(),
        size: _selectedSize,
        errorMessage: 'An unexpected error occurred',
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Delete an image from history
  Future<void> deleteImage(String imageId) async {
    final image = _history.firstWhere(
      (i) => i.id == imageId,
      orElse: () => ImageResult(
        prompt: '',
        model: '',
        size: '',
      ),
    );

    // Delete local file
    if (image.localPath != null) {
      try {
        await File(image.localPath!).delete();
      } catch (_) {}
    }

    _history.removeWhere((i) => i.id == imageId);
    await _saveHistory();
    notifyListeners();
  }

  /// Clear generation error
  void clearError() {
    _error = null;
    _currentGeneration = null;
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    // Delete all local files
    for (final image in _history) {
      if (image.localPath != null) {
        try {
          await File(image.localPath!).delete();
        } catch (_) {}
      }
    }

    _history.clear();
    _currentGeneration = null;
    await _storage.saveImageHistory([]);
    notifyListeners();
  }

  /// Save history to storage
  Future<void> _saveHistory() async {
    await _storage.saveImageHistory(_history);
  }

  /// Get image by ID
  ImageResult? getImage(String imageId) {
    return _history.firstWhere(
      (i) => i.id == imageId,
      orElse: () => ImageResult(
        prompt: '',
        model: '',
        size: '',
      ),
    );
  }
}

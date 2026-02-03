import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

/// Provider for app settings and API configuration
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  final OpenAiService _openAi;

  ThemeMode _themeMode = ThemeMode.system;
  ApiMode _apiMode = ApiMode.byok;
  String? _apiKey;
  String? _serverBaseUrl;
  String _chatModel = AppConstants.defaultChatModel;
  String _imageModel = AppConstants.defaultImageModel;
  bool _isValidating = false;
  bool _isApiValid = false;
  String? _validationError;

  SettingsProvider({
    required StorageService storage,
    required OpenAiService openAi,
  })  : _storage = storage,
        _openAi = openAi;

  // Getters
  ThemeMode get themeMode => _themeMode;
  ApiMode get apiMode => _apiMode;
  String? get apiKey => _apiKey;
  String? get serverBaseUrl => _serverBaseUrl;
  String get chatModel => _chatModel;
  String get imageModel => _imageModel;
  bool get isValidating => _isValidating;
  bool get isApiValid => _isApiValid;
  String? get validationError => _validationError;
  bool get isConfigured => _openAi.isConfigured;

  /// Initialize settings from storage
  Future<void> init() async {
    _themeMode = _parseThemeMode(_storage.getThemeMode());
    _apiMode = _storage.getApiMode();
    _serverBaseUrl = _storage.getServerBaseUrl();
    _chatModel = _storage.getChatModel();
    _imageModel = _storage.getImageModel();

    _apiKey = await _storage.getApiKey();

    _configureOpenAi();
    notifyListeners();

    // Validate on startup if configured, but don't block the app start
    if (isConfigured) {
      validateApi();
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void _configureOpenAi() {
    _openAi.configure(
      apiKey: _apiKey,
      baseUrl: _apiMode == ApiMode.server ? _serverBaseUrl : null,
      apiMode: _apiMode,
    );
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(_themeModeToString(mode));
    notifyListeners();
  }

  /// Set API mode
  Future<void> setApiMode(ApiMode mode) async {
    _apiMode = mode;
    await _storage.saveApiMode(mode);
    _configureOpenAi();
    _isApiValid = false;
    _validationError = null;
    notifyListeners();
  }

  /// Set API key
  Future<void> setApiKey(String key) async {
    _apiKey = key;
    await _storage.saveApiKey(key);
    _configureOpenAi();
    notifyListeners();
  }

  /// Set server base URL
  Future<void> setServerBaseUrl(String url) async {
    _serverBaseUrl = url;
    await _storage.saveServerBaseUrl(url);
    _configureOpenAi();
    notifyListeners();
  }

  /// Set chat model
  Future<void> setChatModel(String model) async {
    _chatModel = model;
    await _storage.saveChatModel(model);
    notifyListeners();
  }

  /// Set image model
  Future<void> setImageModel(String model) async {
    _imageModel = model;
    await _storage.saveImageModel(model);
    notifyListeners();
  }

  /// Validate API configuration
  Future<bool> validateApi() async {
    if (!isConfigured) {
      _validationError = 'API not configured';
      _isApiValid = false;
      notifyListeners();
      return false;
    }

    _isValidating = true;
    _validationError = null;
    notifyListeners();

    try {
      _isApiValid = await _openAi.validateApiKey();
      if (!_isApiValid) {
        _validationError = 'Invalid API key';
      }
    } catch (e) {
      _isApiValid = false;
      _validationError = e.toString();
    }

    _isValidating = false;
    notifyListeners();
    return _isApiValid;
  }

  /// Clear API key
  Future<void> clearApiKey() async {
    _apiKey = null;
    await _storage.deleteApiKey();
    _isApiValid = false;
    _configureOpenAi();
    notifyListeners();
  }

  /// Clear all settings
  Future<void> clearAll() async {
    await _storage.clearAll();
    _themeMode = ThemeMode.system;
    _apiMode = ApiMode.byok;
    _apiKey = null;
    _serverBaseUrl = null;
    _chatModel = AppConstants.defaultChatModel;
    _imageModel = AppConstants.defaultImageModel;
    _isApiValid = false;
    _validationError = null;
    _configureOpenAi();
    notifyListeners();
  }
}

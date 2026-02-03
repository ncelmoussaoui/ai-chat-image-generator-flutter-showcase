import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/chat_session.dart';
import '../models/image_result.dart';
import 'exceptions/api_exception.dart';

/// Service for handling all data persistence
class StorageService {
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw const StorageException(
        message: 'Storage not initialized',
        details: 'Call StorageService.init() before using storage',
      );
    }
    return _prefs!;
  }

  // Secure Storage Methods (for API keys)

  /// Save API key securely
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(
      key: AppConstants.apiKeyStorageKey,
      value: apiKey,
    );
  }

  /// Get API key
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: AppConstants.apiKeyStorageKey);
  }

  /// Delete API key
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: AppConstants.apiKeyStorageKey);
  }

  /// Check if API key exists
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  // SharedPreferences Methods (for settings)

  /// Save API mode
  Future<void> saveApiMode(ApiMode mode) async {
    await _preferences.setString(AppConstants.apiModeStorageKey, mode.name);
  }

  /// Get API mode
  ApiMode getApiMode() {
    final modeStr = _preferences.getString(AppConstants.apiModeStorageKey);
    return ApiMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ApiMode.byok,
    );
  }

  /// Save server base URL
  Future<void> saveServerBaseUrl(String url) async {
    await _preferences.setString(AppConstants.serverBaseUrlStorageKey, url);
  }

  /// Get server base URL
  String? getServerBaseUrl() {
    return _preferences.getString(AppConstants.serverBaseUrlStorageKey);
  }

  /// Save theme mode
  Future<void> saveThemeMode(String mode) async {
    await _preferences.setString(AppConstants.themeModeStorageKey, mode);
  }

  /// Get theme mode
  String getThemeMode() {
    return _preferences.getString(AppConstants.themeModeStorageKey) ?? 'system';
  }

  /// Save chat model
  Future<void> saveChatModel(String model) async {
    await _preferences.setString(AppConstants.chatModelStorageKey, model);
  }

  /// Get chat model
  String getChatModel() {
    return _preferences.getString(AppConstants.chatModelStorageKey) ??
        AppConstants.defaultChatModel;
  }

  /// Save image model
  Future<void> saveImageModel(String model) async {
    await _preferences.setString(AppConstants.imageModelStorageKey, model);
  }

  /// Get image model
  String getImageModel() {
    return _preferences.getString(AppConstants.imageModelStorageKey) ??
        AppConstants.defaultImageModel;
  }

  // Chat History Persistence

  /// Save chat sessions to file
  Future<void> saveChatSessions(List<ChatSession> sessions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_history.json');
      final json = sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      throw StorageException(
        message: 'Failed to save chat history',
        details: e.toString(),
      );
    }
  }

  /// Load chat sessions from file
  Future<List<ChatSession>> loadChatSessions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_history.json');
      if (!await file.exists()) {
        return [];
      }
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as List<dynamic>;
      return json
          .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Image History Persistence

  /// Save image results to file
  Future<void> saveImageHistory(List<ImageResult> images) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/image_history.json');
      final json = images.map((i) => i.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      throw StorageException(
        message: 'Failed to save image history',
        details: e.toString(),
      );
    }
  }

  /// Load image results from file
  Future<List<ImageResult>> loadImageHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/image_history.json');
      if (!await file.exists()) {
        return [];
      }
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as List<dynamic>;
      return json
          .map((i) => ImageResult.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the images directory path
  Future<String> getImagesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/generated_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _preferences.clear();

    final directory = await getApplicationDocumentsDirectory();
    final chatFile = File('${directory.path}/chat_history.json');
    final imageFile = File('${directory.path}/image_history.json');
    final imagesDir = Directory('${directory.path}/generated_images');

    if (await chatFile.exists()) await chatFile.delete();
    if (await imageFile.exists()) await imageFile.delete();
    if (await imagesDir.exists()) await imagesDir.delete(recursive: true);
  }
}

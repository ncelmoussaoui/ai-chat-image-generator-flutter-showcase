/// Application constants including API endpoints, storage keys, and defaults
class AppConstants {
  AppConstants._();

  // API Endpoints
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String responsesEndpoint = '/chat/completions';
  static const String imagesEndpoint = '/images/generations';

  // ---------------------------------------------------------------------------
  // ADMOB CONFIGURATION
  // Replace these with your real AdMob IDs from Google AdMob Console
  // ---------------------------------------------------------------------------
  
  // Android IDs
  static const String androidBannerAdId = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';
  
  // iOS IDs
  static const String iosBannerAdId = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialAdId = 'ca-app-pub-3940256099942544/4411468910';
  
  // Note: App ID (the one with ~) must also be set in:
  // - android/app/src/main/AndroidManifest.xml
  // - ios/Runner/Info.plist
  // ---------------------------------------------------------------------------

  // Storage Keys
  static const String apiKeyStorageKey = 'openai_api_key';
  static const String apiModeStorageKey = 'api_mode';
  static const String serverBaseUrlStorageKey = 'server_base_url';
  static const String themeModeStorageKey = 'theme_mode';
  static const String chatModelStorageKey = 'chat_model';
  static const String imageModelStorageKey = 'image_model';
  static const String chatHistoryStorageKey = 'chat_history';
  static const String imageHistoryStorageKey = 'image_history';

  // Default Values
  static const String defaultChatModel = 'gpt-4o';
  static const String defaultImageModel = 'dall-e-3';
  static const String defaultImageSize = '1024x1024';
  static const int defaultMaxTokens = 4096;
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration streamTimeout = Duration(seconds: 120);

  // Available Models
  static const List<String> chatModels = [
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-4-turbo',
    'gpt-3.5-turbo',
  ];

  static const List<String> imageModels = [
    'dall-e-3',
    'dall-e-2',
  ];

  static const List<String> imageSizes = [
    '1024x1024',
    '1024x1792',
    '1792x1024',
  ];

  // UI Constants
  static const double maxChatBubbleWidth = 0.8;
  static const int maxChatHistorySessions = 50;
  static const int maxImageHistory = 100;
}

/// API mode for key management
enum ApiMode {
  byok, // Bring Your Own Key
  server, // Server-managed key
}

extension ApiModeExtension on ApiMode {
  String get displayName {
    switch (this) {
      case ApiMode.byok:
        return 'BYOK (Your API Key)';
      case ApiMode.server:
        return 'Server Mode';
    }
  }

  String get description {
    switch (this) {
      case ApiMode.byok:
        return 'Enter your OpenAI API key directly';
      case ApiMode.server:
        return 'Connect to a proxy server that handles API keys';
    }
  }
}

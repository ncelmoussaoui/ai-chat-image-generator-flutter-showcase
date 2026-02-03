# 🤖 AI Chat & Image Generator - Flutter Template

> **Professional Flutter template for AI-powered chat and image generation using OpenAI GPT-4 & DALL-E 3**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat&logo=dart)](https://dart.dev)
[![OpenAI](https://img.shields.io/badge/OpenAI-API-412991?style=flat&logo=openai)](https://openai.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)

---

## 🛒 Get the Full Version

Ready to build your own AI-powered app? Get the complete source code with documentation and free updates!

<a href="https://buildautomate.gumroad.com/l/ai-chat-image-generator-flutter">
  <img src="https://img.shields.io/badge/🚀_Buy_on_Gumroad-FF90E8?style=for-the-badge&logo=gumroad&logoColor=black" alt="Buy on Gumroad" />
</a>

**What's included:**
- Complete source code
- Detailed documentation
- Free lifetime updates
- Commercial license

---

## 📱 Screenshots

<p align="center">
  <img src="screenshots/home.png" width="200" alt="Home Screen"/>
  <img src="screenshots/chat_light.png" width="200" alt="Chat Light Mode"/>
  <img src="screenshots/chat_dark.png" width="200" alt="Chat Dark Mode"/>
</p>

<p align="center">
  <img src="screenshots/image_generator.png" width="200" alt="Image Generator"/>
  <img src="screenshots/settings.png" width="200" alt="Settings"/>
</p>

---

## ✨ Features

### AI Chat
- 💬 **Multiple GPT Models** - Support for GPT-4, GPT-4o, GPT-4o-mini, GPT-3.5-Turbo
- ⚡ **Real-time Streaming** - Smooth typewriter-style responses
- 📜 **Chat History** - Persistent conversations saved locally
- 🔄 **Regenerate Responses** - Easily regenerate any AI response
- 📋 **Copy & Share** - Copy messages or share entire conversations

### Image Generation
- 🎨 **DALL-E 3 Integration** - Generate stunning AI images
- 📐 **Multiple Sizes** - Square, Landscape, and Portrait options
- 🖼️ **Image Gallery** - View all generated images in one place
- 💾 **Save & Share** - Download to gallery or share directly
- 🗑️ **Easy Management** - Delete individual or all images

### App Features
- 🌙 **Dark & Light Theme** - Automatic or manual theme switching
- 🔐 **BYOK Mode** - Bring Your Own Key for secure API access
- 📱 **AdMob Ready** - Banner & Interstitial ads pre-integrated
- 🏗️ **Clean Architecture** - Well-organized, maintainable codebase
- 🎯 **Material 3 Design** - Modern UI following Google's guidelines

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter 3.x** | Cross-platform framework |
| **Dart 3.x** | Programming language |
| **Provider** | State management |
| **Dio** | HTTP client with streaming |
| **OpenAI API** | GPT & DALL-E integration |
| **Google Mobile Ads** | Monetization |
| **Shared Preferences** | Local settings storage |
| **Flutter Secure Storage** | Secure API key storage |
| **Path Provider** | File system access |

---

## 📦 Installation

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / VS Code
- OpenAI API Key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ncelmoussaoui/ai-chat-image-generator-flutter-showcase.git
   cd ai-chat-image-generator-flutter-showcase
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## ⚙️ Configuration

### API Key Setup
The app uses a **BYOK (Bring Your Own Key)** model. Users enter their own OpenAI API key in the Settings screen.

1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open the app and go to **Settings**
3. Enter your API key in the designated field
4. Start chatting and generating images!

### AdMob Configuration
To enable ads, update `lib/config/constants.dart`:
```dart
static const String androidBannerAdId = 'your-banner-ad-id';
static const String androidInterstitialAdId = 'your-interstitial-ad-id';
static const String iosBannerAdId = 'your-ios-banner-ad-id';
static const String iosInterstitialAdId = 'your-ios-interstitial-ad-id';
```

### Change Package Name
```bash
flutter pub run change_app_package_name:main com.yourcompany.yourapp
```

---

## 📁 Project Structure

```
lib/
├── config/           # App configuration
│   ├── constants.dart    # API endpoints, Ad IDs
│   └── theme.dart        # Light & Dark themes
├── models/           # Data models
│   ├── message.dart      # Chat message model
│   └── generated_image.dart  # Image model
├── providers/        # State management
│   ├── chat_provider.dart
│   ├── image_provider.dart
│   └── settings_provider.dart
├── services/         # Business logic
│   ├── openai_service.dart   # API integration
│   ├── storage_service.dart  # Local storage
│   └── ad_service.dart       # AdMob integration
├── screens/          # UI screens
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── image_screen.dart
│   └── settings_screen.dart
└── main.dart         # App entry point
```

---

## 🚀 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web (limited features)
- ✅ macOS
- ✅ Windows
- ✅ Linux

---

## 🤝 Support

Need help? Have questions?

- 📧 **Email:** [Contact via Gumroad](https://buildautomate.gumroad.com/l/ai-chat-image-generator-flutter)
- 🐛 **Issues:** [GitHub Issues](https://github.com/ncelmoussaoui/ai-chat-image-generator-flutter-showcase/issues)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🛒 Get the Full Version

<a href="https://buildautomate.gumroad.com/l/ai-chat-image-generator-flutter">
  <img src="https://img.shields.io/badge/🚀_Buy_on_Gumroad-FF90E8?style=for-the-badge&logo=gumroad&logoColor=black" alt="Buy on Gumroad" />
</a>

**Build your own AI app today!**

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/ncelmoussaoui">ncelmoussaoui</a>
</p>

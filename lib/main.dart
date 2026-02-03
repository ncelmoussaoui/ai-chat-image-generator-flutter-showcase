import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/image_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/image_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/connectivity_service.dart';
import 'services/openai_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize AdMob
    await AdService.init();

    // Initialize core services
    final storageService = StorageService();
    await storageService.init();

    final openAiService = OpenAiService();
    final connectivityService = ConnectivityService();
    await connectivityService.init();

    // Initialize providers
    final settingsProvider = SettingsProvider(
      storage: storageService,
      openAi: openAiService,
    );
    await settingsProvider.init();

    final chatProvider = ChatProvider(
      openAi: openAiService,
      storage: storageService,
      connectivity: connectivityService,
    );
    await chatProvider.init();

    final imageProvider = ImageGeneratorProvider(
      openAi: openAiService,
      storage: storageService,
      connectivity: connectivityService,
    );
    await imageProvider.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: chatProvider),
          ChangeNotifierProvider.value(value: imageProvider),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e) {
    // Fallback UI in case of initialization error
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'AI Chat & Image Generator',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/chat': (context) => const ChatScreen(),
            '/image': (context) => const ImageScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

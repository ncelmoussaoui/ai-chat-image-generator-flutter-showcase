import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/settings_provider.dart';

/// Settings screen for API configuration and app preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController.text = settings.apiKey ?? '';
    _serverUrlController.text = settings.serverBaseUrl ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: 'Appearance',
                children: [
                  _buildThemeSetting(settings),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'API Configuration',
                children: [
                  _buildApiModeSetting(settings),
                  const SizedBox(height: 16),
                  if (settings.apiMode == ApiMode.byok)
                    _buildApiKeySetting(settings)
                  else
                    _buildServerUrlSetting(settings),
                  const SizedBox(height: 16),
                  _buildValidationStatus(settings),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Models',
                children: [
                  _buildChatModelSetting(settings),
                  const SizedBox(height: 16),
                  _buildImageModelSetting(settings),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Data',
                children: [
                  _buildClearDataButton(settings),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme'),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_system_daydream),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selection) {
            settings.setThemeMode(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildApiModeSetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('API Mode'),
        const SizedBox(height: 8),
        SegmentedButton<ApiMode>(
          segments: ApiMode.values
              .map((mode) => ButtonSegment(
                    value: mode,
                    label: Text(mode == ApiMode.byok ? 'BYOK' : 'Server'),
                  ))
              .toList(),
          selected: {settings.apiMode},
          onSelectionChanged: (selection) {
            settings.setApiMode(selection.first);
          },
        ),
        const SizedBox(height: 8),
        Text(
          settings.apiMode.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildApiKeySetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OpenAI API Key'),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          decoration: InputDecoration(
            hintText: 'sk-...',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await settings.setApiKey(_apiKeyController.text);
                    await settings.validateApi();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerUrlSetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Server Base URL'),
        const SizedBox(height: 8),
        TextField(
          controller: _serverUrlController,
          decoration: InputDecoration(
            hintText: 'https://your-server.com/api',
            // TODO: Replace with your server URL
            suffixIcon: IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                await settings.setServerBaseUrl(_serverUrlController.text);
                await settings.validateApi();
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your proxy server URL that handles OpenAI API requests',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildValidationStatus(SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;

    if (settings.isValidating) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Validating API...'),
        ],
      );
    }

    if (!settings.isConfigured) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'API not configured',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    if (settings.isApiValid) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'API key is valid',
            style: TextStyle(color: colorScheme.primary),
          ),
        ],
      );
    }

    if (settings.validationError != null) {
      return Row(
        children: [
          Icon(Icons.error, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              settings.validationError!,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      );
    }

    return FilledButton(
      onPressed: () => settings.validateApi(),
      child: const Text('Validate API'),
    );
  }

  Widget _buildChatModelSetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chat Model'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: settings.chatModel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: AppConstants.chatModels
              .map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setChatModel(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildImageModelSetting(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image Model'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: settings.imageModel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: AppConstants.imageModels
              .map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setImageModel(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildClearDataButton(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showClearDataDialog(settings),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Clear All Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This will delete all chat history, images, and settings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _showClearDataDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your chat history, generated images, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await settings.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

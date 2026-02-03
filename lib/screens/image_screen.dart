import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/constants.dart';
import '../models/image_result.dart';
import '../providers/image_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import '../services/gallery_service.dart';
import 'widgets/empty_state.dart';
import 'widgets/image_card.dart';
import 'widgets/message_input_bar.dart';

/// Image generation screen
class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Generator'),
        actions: [
          Consumer<ImageGeneratorProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(value, provider),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'size',
                    child: ListTile(
                      leading: Icon(Icons.aspect_ratio),
                      title: Text('Image Size'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Clear History'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<ImageGeneratorProvider, SettingsProvider>(
        builder: (context, imageProvider, settings, child) {
          if (!settings.isConfigured) {
            return EmptyState(
              icon: Icons.key,
              title: 'API Not Configured',
              subtitle: 'Please configure your OpenAI API key in settings',
              action: FilledButton(
                onPressed: () => _openSettings(),
                child: const Text('Open Settings'),
              ),
            );
          }

          return Column(
            children: [
              if (imageProvider.error != null)
                _buildErrorBanner(imageProvider),
              _buildSizeSelector(imageProvider),
              Expanded(
                child: imageProvider.hasHistory
                    ? _buildImageGrid(imageProvider)
                    : _buildEmptyState(),
              ),
              MessageInputBar(
                hintText: 'Describe the image you want to create...',
                enabled: !imageProvider.isGenerating,
                isLoading: imageProvider.isGenerating,
                onSend: (prompt) {
                  // Show interstitial ad before starting generation
                  AdService.showInterstitialAd();

                  imageProvider.generateImage(
                    prompt,
                    model: settings.imageModel,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(ImageGeneratorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialBanner(
      content: Text(provider.error ?? 'An error occurred'),
      backgroundColor: colorScheme.errorContainer,
      contentTextStyle: TextStyle(color: colorScheme.onErrorContainer),
      leading: Icon(Icons.error, color: colorScheme.error),
      actions: [
        TextButton(
          onPressed: () => provider.clearError(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildSizeSelector(ImageGeneratorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Size:',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SegmentedButton<String>(
              segments: AppConstants.imageSizes
                  .map((size) => ButtonSegment(
                        value: size,
                        label: Text(
                          size.split('x').first,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ))
                  .toList(),
              selected: {provider.selectedSize},
              onSelectionChanged: (selection) {
                provider.setSize(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(ImageGeneratorProvider provider) {
    final images = provider.history;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return ImageCard(
          image: image,
          onTap: () => _showImagePreview(image),
          onDelete: () => _confirmDelete(provider, image.id),
          onShare: image.isCompleted ? () => _shareImage(image) : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.image_outlined,
      title: 'Create Your First Image',
      subtitle: 'Describe what you want to see and AI will generate it',
    );
  }

  void _handleMenuAction(String action, ImageGeneratorProvider provider) {
    switch (action) {
      case 'size':
        _showSizeDialog(provider);
        break;
      case 'clear':
        _showClearConfirmation(provider);
        break;
    }
  }

  void _showSizeDialog(ImageGeneratorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.imageSizes.map((size) {
            final isSelected = size == provider.selectedSize;
            return ListTile(
              title: Text(size),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () {
                provider.setSize(size);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(ImageGeneratorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all generated images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearAllHistory();
              Navigator.pop(context);
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

  void _showImagePreview(ImageResult image) {
    if (!image.hasImageData) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImagePreviewScreen(image: image),
      ),
    );
  }

  void _confirmDelete(ImageGeneratorProvider provider, String imageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will permanently delete this image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteImage(imageId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareImage(ImageResult image) async {
    if (image.localPath != null) {
      await Share.shareXFiles(
        [XFile(image.localPath!)],
        text: image.prompt,
      );
    } else if (image.imageUrl != null) {
      await Share.share(
        '${image.prompt}\n\n${image.imageUrl}',
      );
    }
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }
}

/// Fullscreen image preview
class _ImagePreviewScreen extends StatelessWidget {
  final ImageResult image;

  const _ImagePreviewScreen({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _saveToGallery(context),
            tooltip: 'Save to Gallery',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(image),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: 'image_${image.id}',
              child: PhotoView(
                imageProvider: image.localPath != null
                    ? FileImage(File(image.localPath!))
                    : NetworkImage(image.imageUrl!) as ImageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  image.revisedPrompt ?? image.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(context, image.model),
                    const SizedBox(width: 8),
                    _buildInfoChip(context, image.size),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    if (image.localPath == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await GalleryService.saveImage(image.localPath!);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  void _shareImage(ImageResult image) async {
    if (image.localPath != null) {
      await Share.shareXFiles(
        [XFile(image.localPath!)],
        text: image.prompt,
      );
    }
  }
}

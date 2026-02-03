import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/image_result.dart';

/// Image card widget for displaying generated images
class ImageCard extends StatelessWidget {
  final ImageResult image;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const ImageCard({
    super.key,
    required this.image,
    this.onTap,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'image_${image.id}',
                child: _buildImage(context),
              ),
            ),
            _buildInfo(context, colorScheme, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (image.isGenerating) {
      return Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'Generating...',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (image.hasError) {
      return Container(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 24,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  image.errorMessage ?? 'Error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (image.localPath != null) {
      return Image.file(
        File(image.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(colorScheme);
        },
      );
    }

    if (image.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: image.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return _buildPlaceholder(colorScheme);
        },
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildInfo(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            image.prompt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  image.size,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null && image.isCompleted)
                    _CardActionButton(
                      icon: Icons.share_outlined,
                      onPressed: onShare!,
                      color: colorScheme.primary,
                    ),
                  if (onDelete != null)
                    _CardActionButton(
                      icon: Icons.delete_outline,
                      onPressed: onDelete!,
                      color: colorScheme.error.withValues(alpha: 0.8),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _CardActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 16,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      color: color,
      splashRadius: 20,
    );
  }
}

/// Large image preview for fullscreen viewing
class ImagePreview extends StatelessWidget {
  final ImageResult image;

  const ImagePreview({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'image_${image.id}',
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    if (image.localPath != null) {
      return Image.file(
        File(image.localPath!),
        fit: BoxFit.contain,
      );
    }

    if (image.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: image.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.image_not_supported),
    );
  }
}

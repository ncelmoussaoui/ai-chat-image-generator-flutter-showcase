import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/chat_message.dart';

/// Chat message bubble widget
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 8,
          right: isUser ? 8 : 48,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: _buildContent(context, isUser),
            ),
            if (!message.isStreaming) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (message.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.errorMessage ?? 'An error occurred',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (message.isStreaming && message.content.isEmpty) {
      return const TypingIndicatorDots();
    }

    if (isUser) {
      return Text(
        message.content,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 15,
        ),
      );
    }

    // Assistant message with markdown
    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 15,
          height: 1.5,
        ),
        code: TextStyle(
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: colorScheme.primary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        h1: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!message.hasError && message.content.isNotEmpty)
            _ActionButton(
              icon: Icons.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
                onCopy?.call();
              },
            ),
          if (message.hasError && onRetry != null)
            _ActionButton(
              icon: Icons.refresh,
              onPressed: onRetry,
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 16,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      color: color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}

/// Animated typing indicator dots
class TypingIndicatorDots extends StatefulWidget {
  const TypingIndicatorDots({super.key});

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animation * 2 - 1).abs()));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

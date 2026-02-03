import 'package:flutter/material.dart';

/// Message input bar widget for chat and image prompts
class MessageInputBar extends StatefulWidget {
  final String hintText;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onStop;
  final ValueChanged<String> onSend;
  final int maxLines;
  final TextEditingController? controller;

  const MessageInputBar({
    super.key,
    this.hintText = 'Type a message...',
    this.enabled = true,
    this.isLoading = false,
    this.onStop,
    required this.onSend,
    this.maxLines = 5,
    this.controller,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: widget.enabled ? (_) => _handleSend() : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    if (widget.isLoading) {
      return IconButton.filled(
        onPressed: widget.onStop,
        icon: const Icon(Icons.stop),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        ),
      );
    }

    return IconButton.filled(
      onPressed: _hasText && widget.enabled ? _handleSend : null,
      icon: const Icon(Icons.send),
      style: IconButton.styleFrom(
        backgroundColor:
            _hasText ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        foregroundColor:
            _hasText ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

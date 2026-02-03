import 'package:flutter/material.dart';

/// Animated typing indicator widget
class TypingIndicator extends StatefulWidget {
  final bool isVisible;
  final Color? dotColor;
  final double dotSize;

  const TypingIndicator({
    super.key,
    this.isVisible = true,
    this.dotColor,
    this.dotSize = 8.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dot1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _dot2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _dot3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );

    if (widget.isVisible) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = widget.dotColor ?? colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(dotColor, _dot1Animation.value),
            const SizedBox(width: 4),
            _buildDot(dotColor, _dot2Animation.value),
            const SizedBox(width: 4),
            _buildDot(dotColor, _dot3Animation.value),
          ],
        );
      },
    );
  }

  Widget _buildDot(Color color, double animationValue) {
    final offset = -4.0 * animationValue;

    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5 + (0.5 * animationValue)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Loading indicator container that wraps content with a loading overlay
class LoadingIndicatorContainer extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingIndicatorContainer({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        if (message != null) ...[
                          const SizedBox(height: 16),
                          Text(message!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

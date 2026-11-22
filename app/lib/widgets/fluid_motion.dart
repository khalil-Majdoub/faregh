import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives cards, chips, and buttons a subtle, physical press response.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.975,
    this.enableHaptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled
          ? () {
              if (widget.enableHaptic) {
                HapticFeedback.selectionClick();
              }
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 115),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Smoothly animates numeric values (wait minutes, ticket numbers) with subtle vertical slide.
class AnimatedCountText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const AnimatedCountText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.22),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
      ),
    );
  }
}

/// Calm breathing status dot for live indicators (no distracting flash).
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * (1.25 + 0.65 * t),
                  height: widget.size * (1.25 + 0.65 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withAlpha(((1.0 - t) * 70).round()),
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

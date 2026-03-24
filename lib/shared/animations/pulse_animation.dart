import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color color;
  final int ringCount;

  const PulseAnimation({
    super.key,
    required this.child,
    required this.isActive,
    this.color = AppColors.accent,
    this.ringCount = 3,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isActive)
              ...List.generate(widget.ringCount, (i) {
                final delay = i / widget.ringCount;
                final progress = ((_animation.value + delay) % 1.0);
                return Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 0.5),
                  child: Transform.scale(
                    scale: 1.0 + (progress * 0.5),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            widget.child,
          ],
        );
      },
    );
  }
}

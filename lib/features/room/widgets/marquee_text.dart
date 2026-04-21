import 'package:flutter/material.dart';

/// Continuously scrolling single-line text ("marquee") that moves
/// right → left. Uses a duplicated text pair so the loop is seamless.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Horizontal scroll speed in logical pixels per second.
  final double speed;

  /// Gap between the two duplicated text runs.
  final double gap;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.speed = 45,
    this.gap = 60,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _textWidth;

  @override
  void initState() {
    super.initState();
    _measureTextWidth();
    _controller = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.speed != widget.speed ||
        oldWidget.gap != widget.gap) {
      _measureTextWidth();
      _controller.duration = _cycleDuration;
      _controller
        ..reset()
        ..repeat();
    }
  }

  void _measureTextWidth() {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    _textWidth = tp.width;
  }

  Duration get _cycleDuration {
    final distance = _textWidth + widget.gap;
    final seconds = distance / widget.speed;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cycleDistance = _textWidth + widget.gap;
    return ClipRect(
      // OverflowBox lets the inner Row measure its natural (unbounded) width
      // so long strings don't hit the RenderFlex overflow striping. ClipRect
      // still trims anything outside the parent's bounds.
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = -_controller.value * cycleDistance;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.text, style: widget.style, maxLines: 1),
                  SizedBox(width: widget.gap),
                  Text(widget.text, style: widget.style, maxLines: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Constrains its child to a max width on wide viewports (web/desktop) and
/// centers it horizontally. On viewports narrower than [maxWidth] it is a
/// no-op, so the child fills the available width as on mobile.
///
/// Uses symmetric padding rather than `Align` + `ConstrainedBox` so that
/// the child still receives bounded height constraints — important for
/// `ListView`, `Column` with `Expanded`, etc.
class WebMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebMaxWidth({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= maxWidth) return child;
        final pad = (width - maxWidth) / 2;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        );
      },
    );
  }
}

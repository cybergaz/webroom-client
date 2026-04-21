import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/shell/widgets/floating_pill_navbar.dart';

/// Pill-shaped overlay snackbar with fade + slide animations on both
/// insert and dismiss, a close button, and positioned above the
/// [FloatingPillNavBar] with a 10px gap.
class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _currentEntry;
  static _AppSnackBarState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // If a snackbar is already showing, dismiss it first and queue the new one.
    final existing = _currentState;
    if (existing != null) {
      existing.dismiss().then((_) {
        _insert(
          overlay,
          message: message,
          isError: isError,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      });
      return;
    }
    _insert(
      overlay,
      message: message,
      isError: isError,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _insert(
    OverlayState overlay, {
    required String message,
    required bool isError,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!overlay.mounted) return;

    final stateKey = GlobalKey<_AppSnackBarState>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppSnackBar(
        key: stateKey,
        message: message,
        isError: isError,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentState = null;
          }
          entry.remove();
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentState = stateKey.currentState;
    });
  }
}

class _AppSnackBar extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _AppSnackBar({
    super.key,
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AppSnackBar> createState() => _AppSnackBarState();
}

class _AppSnackBarState extends State<_AppSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _autoDismissTimer = Timer(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isError
        ? const Color(0xFFD33A3A)
        : AppColors.textPrimary;
    return Positioned(
      left: 16,
      right: 16,
      bottom: FloatingPillNavBar.bottomPadding(context) + 10,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onAction?.call();
                        dismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentLight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: dismiss,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.white.withValues(alpha: 0.75),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

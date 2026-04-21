import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

enum NavDestination { rooms, recordings, sessionHistory, settings }

class FloatingPillNavBar extends StatelessWidget {
  final NavDestination current;

  const FloatingPillNavBar({super.key, required this.current});

  static const double height = 64;
  static const double bottomInset = 16;
  static const double horizontalInset = 20;

  /// Space a screen should reserve at the bottom so scrolled content
  /// doesn't hide underneath the navbar.
  static double bottomPadding(BuildContext context) =>
      height + bottomInset + MediaQuery.of(context).padding.bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          horizontalInset,
          0,
          horizontalInset,
          bottomInset,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      icon: Icons.meeting_room_rounded,
                      label: 'Rooms',
                      active: current == NavDestination.rooms,
                      onTap: () => context.go('/home'),
                    ),
                  ),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.mic_external_on_rounded,
                      label: 'Recordings',
                      active: current == NavDestination.recordings,
                      onTap: () => context.go('/recordings'),
                    ),
                  ),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.history_rounded,
                      label: 'History',
                      active: current == NavDestination.sessionHistory,
                      onTap: () => context.go('/session-history'),
                    ),
                  ),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      active: current == NavDestination.settings,
                      onTap: () => context.go('/settings'),
                    ),
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

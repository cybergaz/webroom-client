import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'floating_pill_navbar.dart';

/// Persistent shell that keeps the pill navbar mounted across tab navigations.
/// Routes wrapped by [ShellRoute] share this single shell instance, so the
/// navbar does not rebuild or flicker when switching between tabs.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final current = _destinationForLocation(location);

    return Stack(
      children: [
        Positioned.fill(child: child),
        if (current != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingPillNavBar(current: current),
          ),
      ],
    );
  }

  NavDestination? _destinationForLocation(String path) {
    if (path.startsWith('/home')) return NavDestination.rooms;
    if (path.startsWith('/recordings')) return NavDestination.recordings;
    if (path.startsWith('/session-history')) {
      return NavDestination.sessionHistory;
    }
    if (path.startsWith('/settings')) return NavDestination.settings;
    return null;
  }
}

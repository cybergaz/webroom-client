import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/websocket_service.dart';
import 'auth_provider.dart';

/// Reason the user was forced out. Stored briefly so the login screen can show a message.
class SessionKickReason {
  final String message;
  SessionKickReason(this.message);
}

/// Holds the most recent kick reason (if any). Cleared when consumed.
class SessionKickReasonNotifier extends Notifier<SessionKickReason?> {
  @override
  SessionKickReason? build() => null;

  void set(SessionKickReason? reason) => state = reason;
}

final sessionKickReasonProvider =
    NotifierProvider<SessionKickReasonNotifier, SessionKickReason?>(
  SessionKickReasonNotifier.new,
);

/// Global listener that watches for server-initiated session termination events
/// (`user.session_replaced`, `user.force_logout`) and triggers force logout.
///
/// Activated by watching it in the app root.
final sessionGuardProvider = Provider<void>((ref) {
  StreamSubscription? sub;

  final auth = ref.watch(authStateProvider);
  if (auth is! AuthStateAuthenticated) {
    sub?.cancel();
    return;
  }

  final wsService = ref.read(websocketServiceProvider);
  sub = wsService.events.listen((event) {
    final eventName = event['event'] as String?;
    final payload = event['payload'] as Map<String, dynamic>? ?? {};

    if (eventName == 'user.session_replaced') {
      final reason = payload['reason'] as String? ??
          'You have been logged out because a new login was detected on another device.';
      ref.read(sessionKickReasonProvider.notifier).set(SessionKickReason(reason));
      ref.read(authStateProvider.notifier).forceLogout();
    }

    if (eventName == 'user.force_logout') {
      final reason = payload['reason'] as String? ?? 'Logged out by administrator';
      ref.read(sessionKickReasonProvider.notifier).set(SessionKickReason(reason));
      ref.read(authStateProvider.notifier).forceLogout();
    }
  });

  ref.onDispose(() => sub?.cancel());
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/enums/ws_connection_state.dart';
import '../../core/theme/app_colors.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsService = ref.watch(websocketServiceProvider);

    return StreamBuilder<WsConnectionState>(
      stream: wsService.connectionState,
      initialData: wsService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? WsConnectionState.disconnected;

        if (state == WsConnectionState.connected) {
          return const SizedBox.shrink();
        }

        final isReconnecting = state == WsConnectionState.reconnecting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isReconnecting ? AppColors.warning.withValues(alpha: 0.9) : AppColors.error.withValues(alpha: 0.9),
          child: Row(
            children: [
              if (isReconnecting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                isReconnecting ? 'Reconnecting...' : 'Disconnected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }
}

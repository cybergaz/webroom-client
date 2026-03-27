import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/getstream_provider.dart';
import '../providers/ptt_provider.dart';
import '../providers/room_session_provider.dart';

/// A draggable floating mini-player shown when the user navigates away
/// from a room while a call is still active.
class ActiveCallOverlay extends ConsumerStatefulWidget {
  const ActiveCallOverlay({super.key});

  @override
  ConsumerState<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends ConsumerState<ActiveCallOverlay> {
  Offset _position = const Offset(16, 80);

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(activeCallProvider);
    final session = ref.watch(roomSessionProvider).value;
    final ptt = ref.watch(pttStateProvider);
    final isOnRoomScreen = ref.watch(isOnRoomScreenProvider);

    // Only show when there's an active call and we're NOT on the room screen.
    print("overlay: call=${call != null}, session=${session != null}, isInCall=${session?.isInCall}, isOnRoomScreen=$isOnRoomScreen");
    if (call == null || session == null || !session.isInCall) {
      return const SizedBox.shrink();
    }
    if (isOnRoomScreen) return const SizedBox.shrink();

    final router = ref.read(appRouterProvider);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onTap: () {
          router.go('/room/${session.roomId}');
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Room name + close button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.roomName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(pttStateProvider.notifier).stopTransmitting();
                        if (session.isHost) {
                          await ref.read(roomSessionProvider.notifier).endRoom();
                        } else {
                          await ref.read(roomSessionProvider.notifier).leaveRoom();
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mini PTT button
                GestureDetector(
                  onTapDown: (_) {
                    HapticFeedback.mediumImpact();
                    ref.read(pttStateProvider.notifier).startTransmitting();
                  },
                  onTapUp: (_) {
                    HapticFeedback.lightImpact();
                    ref.read(pttStateProvider.notifier).stopTransmitting();
                  },
                  onTapCancel: () {
                    ref.read(pttStateProvider.notifier).stopTransmitting();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ptt.isTransmitting
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                      border: Border.all(
                        color: ptt.isTransmitting
                            ? AppColors.accent
                            : AppColors.error.withValues(alpha: 0.5),
                        width: ptt.isTransmitting ? 2.5 : 1.5,
                      ),
                      boxShadow: ptt.isTransmitting
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      ptt.isTransmitting
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      color: ptt.isTransmitting ? Colors.white : AppColors.error,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

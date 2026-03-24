import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import '../providers/getstream_provider.dart';
import '../providers/room_session_provider.dart';
import '../providers/ptt_provider.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const UserRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId);
      _subscribeToForceEvents();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _subscribeToForceEvents() {
    final wsService = ref.read(websocketServiceProvider);
    final storage = ref.read(secureStorageProvider);

    _wsSub = wsService.events.listen((event) async {
      final eventName = event['event'] as String;
      final payload = event['payload'] as Map<String, dynamic>? ?? {};
      final myId = await storage.read(StorageKeys.userId);

      if (!mounted) return;

      if (eventName == 'room.member_kicked' &&
          payload['roomId'] == widget.roomId &&
          payload['userId'] == myId) {
        await ref.read(roomSessionProvider.notifier).leaveRoom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You were removed from the room')),
          );
          context.go('/home');
        }
      }

      if (eventName == 'user.force_logout' && payload['userId'] == myId) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(roomSessionProvider);
    final pttState = ref.watch(pttStateProvider);

    ref.listen(roomSessionProvider, (_, next) {
      next.whenData((session) {
        if (session.isEnded && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Room ended by host')));
          context.go('/home');
        }
      });
    });

    final call = ref.watch(activeCallProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (call == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: StreamCallContainer(
                  call: call,
                  // callContentWidgetBuilder: (context, call) {
                  //     return MyOwnCallContent(call: call);
                  // },
                ),
              ),
            // const ConnectionStatusBar(),
            // sessionAsync.when(
            //   loading: () => const SizedBox.shrink(),
            //   error: (_, _) => const SizedBox.shrink(),
            //   data: (session) => RoomHeader(
            //     roomId: widget.roomId,
            //     roomName: session.roomName,
            //   ),
            // ),
            // Expanded(
            //   child: sessionAsync.when(
            //     loading: () => const Center(child: CircularProgressIndicator()),
            //     error: (e, _) => Center(
            //       child: Text(mapErrorToMessage(e), style: const TextStyle(color: AppColors.error)),
            //     ),
            //     data: (session) => switch ((session.isInCall, session.status)) {
            //       (true, _) => Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             PulseAnimation(
            //               isActive: pttState.isTransmitting,
            //               color: AppColors.accent,
            //               child: const PttButton(),
            //             ),
            //             const SizedBox(height: 32),
            //             const PttWaveform(),
            //           ],
            //         ),
            //       (false, RoomStatus.live) => _JoinView(
            //           onJoin: () => ref.read(roomSessionProvider.notifier).joinRoomAndEnter(),
            //         ),
            //       (false, RoomStatus.active) => _WaitingView(
            //           onRefresh: () => ref.read(roomSessionProvider.notifier).refreshRoom(),
            //         ),
            //       (false, RoomStatus.inactive) => const _DisabledView(),
            //       (false, RoomStatus.ended) => const _DisabledView(message: 'This room has ended.'),
            //     },
            //   ),
            // ),
            // sessionAsync.maybeWhen(
            //   data: (session) => session.isInCall
            //       ? Padding(
            //           padding: const EdgeInsets.all(24),
            //           child: SizedBox(
            //             width: double.infinity,
            //             child: OutlinedButton.icon(
            //               style: OutlinedButton.styleFrom(
            //                 foregroundColor: AppColors.error,
            //                 side: const BorderSide(color: AppColors.error),
            //               ),
            //               icon: const Icon(Icons.call_end_rounded),
            //               label: const Text('Leave Room'),
            //               onPressed: () async {
            //                 await ref.read(pttStateProvider.notifier).stopTransmitting();
            //                 await ref.read(roomSessionProvider.notifier).leaveRoom();
            //                 if (context.mounted) context.go('/home');
            //               },
            //             ),
            //           ),
            //         )
            //       : const SizedBox.shrink(),
            //   orElse: () => const SizedBox.shrink(),
            // ),
          ],
        ),
      ),
    );
  }
}

class _JoinView extends StatelessWidget {
  final VoidCallback onJoin;

  const _JoinView({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.spatial_audio_rounded,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 24),
          const Text(
            'Room is live',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The host has started the session.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.headset_rounded),
              label: const Text('Join Room', style: TextStyle(fontSize: 16)),
              onPressed: onJoin,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _WaitingView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for host',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The host has not started the session yet.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Check Again'),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _DisabledView extends StatelessWidget {
  final String message;

  const _DisabledView({this.message = 'This room has been disabled by admin.'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 24),
          const Text(
            'Room Unavailable',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

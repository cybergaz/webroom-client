import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_video/stream_video.dart';

import '../providers/getstream_provider.dart';
import '../providers/room_session_provider.dart';
import '../providers/ptt_provider.dart';
import '../widgets/call_controls_bar.dart';
import '../widgets/participants_grid.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const UserRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  StreamSubscription? _wsSub;
  late final IsOnRoomScreenNotifier _roomScreenNotifier;
  Timer? _graceCountdownTimer;
  int _graceSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _roomScreenNotifier = ref.read(isOnRoomScreenProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roomScreenNotifier.set(true);
      ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId);
      _subscribeToForceEvents();
    });
  }

  @override
  void dispose() {
    Future.microtask(() => _roomScreenNotifier.set(false));
    _graceCountdownTimer?.cancel();
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

  void _startGraceCountdown(int totalSeconds) {
    _graceCountdownTimer?.cancel();
    _graceSecondsRemaining = totalSeconds;
    _graceCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _graceCountdownTimer?.cancel();
        return;
      }
      setState(() {
        _graceSecondsRemaining = (_graceSecondsRemaining - 1).clamp(0, totalSeconds);
      });
    });
  }

  void _stopGraceCountdown() {
    _graceCountdownTimer?.cancel();
    if (mounted) setState(() => _graceSecondsRemaining = 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomSessionProvider, (prev, next) {
      next.whenData((session) {
        if (session.isEnded && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Room ended by host')));
          context.go('/home');
        }

        final wasDisconnected = prev?.value?.isHostDisconnected ?? false;
        if (session.isHostDisconnected && !wasDisconnected) {
          _startGraceCountdown(session.hostGraceSeconds);
        } else if (!session.isHostDisconnected && wasDisconnected) {
          _stopGraceCountdown();
        }
      });
    });

    final call = ref.watch(activeCallProvider);
    final sessionState = ref.watch(roomSessionProvider);
    final roomName = sessionState.isLoading
        ? ''
        : (sessionState.value?.roomName ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          roomName.isEmpty ? '' : roomName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Host disconnection warning banner
            if (sessionState.value?.isHostDisconnected == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.warning,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Host disconnected. Room will end in ${_graceSecondsRemaining}s...',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (call == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Participants area
              Expanded(child: ParticipantsGrid(call: call, hostOnly: true)),
              _buildControls(call),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(Call call) {
    final ptt = ref.watch(pttStateProvider);
    return CallControlsBar(
      call: call,
      isHost: false,
      isTransmitting: ptt.isTransmitting,
      audioLevel: ptt.audioLevel,
      onPttDown: () => ref.read(pttStateProvider.notifier).startTransmitting(),
      onPttUp: () => ref.read(pttStateProvider.notifier).stopTransmitting(),
      onEndOrLeave: () async {
        await ref.read(pttStateProvider.notifier).stopTransmitting();
        await ref.read(roomSessionProvider.notifier).leaveRoom();
        if (context.mounted) context.go('/home');
      },
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

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
import '../../../domain/enums/room_status.dart';
import '../../auth/providers/auth_provider.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const UserRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  StreamSubscription? _wsSub;
  bool _isJoining = false;

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

      // When host starts the room, auto-refresh so user sees the Join button.
      if (eventName == 'room.started' &&
          payload['roomId'] == widget.roomId) {
        ref.read(roomSessionProvider.notifier).refreshRoom();
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
    final session = sessionAsync.value;
    final roomName = session?.roomName ?? '';

    ref.listen(roomSessionProvider, (_, next) {
      next.whenData((session) {
        if (session.isEnded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room ended by host')),
          );
          context.go('/home');
        }
      });
    });

    final call = ref.watch(activeCallProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(roomName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: _buildBody(sessionAsync, call),
      ),
    );
  }

  Widget _buildBody(AsyncValue<RoomSession> sessionAsync, Call? call) {
    // Loading state
    if (sessionAsync.isLoading && sessionAsync.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (sessionAsync.hasError && sessionAsync.value == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                sessionAsync.error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final session = sessionAsync.value;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Already in the call — show participants + controls
    if (session.isInCall && call != null) {
      return Column(
        children: [
          Expanded(child: ParticipantsGrid(call: call)),
          _buildControls(call),
        ],
      );
    }

    // Room is live but user hasn't joined yet — show Join button
    if (session.status == RoomStatus.live) {
      return _JoinView(
        isJoining: _isJoining,
        onJoin: () async {
          setState(() => _isJoining = true);
          try {
            await ref.read(roomSessionProvider.notifier).joinRoomAndEnter();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to join: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isJoining = false);
          }
        },
      );
    }

    // Room not live yet — waiting for host to start
    return _WaitingView(
      onRefresh: () => ref.read(roomSessionProvider.notifier).refreshRoom(),
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
  final bool isJoining;
  final VoidCallback onJoin;

  const _JoinView({required this.isJoining, required this.onJoin});

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
              icon: isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.headset_rounded),
              label: Text(
                isJoining ? 'Joining...' : 'Join Room',
                style: const TextStyle(fontSize: 16),
              ),
              onPressed: isJoining ? null : onJoin,
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

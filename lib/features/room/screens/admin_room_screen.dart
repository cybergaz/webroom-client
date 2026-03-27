import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_video/stream_video.dart';

import '../providers/getstream_provider.dart';
import '../providers/room_session_provider.dart';
import '../providers/ptt_provider.dart';
import '../widgets/call_controls_bar.dart';
import '../widgets/participants_grid.dart';
import 'call_participants_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class AdminRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const AdminRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<AdminRoomScreen> createState() => _AdminRoomScreenState();
}

class _AdminRoomScreenState extends ConsumerState<AdminRoomScreen> {
  late final IsOnRoomScreenNotifier _roomScreenNotifier;

  @override
  void initState() {
    super.initState();
    _roomScreenNotifier = ref.read(isOnRoomScreenProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roomScreenNotifier.set(true);
      ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    Future.microtask(() => _roomScreenNotifier.set(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(roomSessionProvider);
    final roomName = sessionState.isLoading ? '' : (sessionState.value?.roomName ?? '');

    ref.listen(roomSessionProvider, (_, next) {
      next.whenData((session) {
        if (session.isEnded && mounted) {
          context.go('/home');
        }
      });
    });

    final call = ref.watch(activeCallProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          roomName.isEmpty ? '' : roomName,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (call != null)
            IconButton(
              icon: const Icon(Icons.people_rounded, color: AppColors.textSecondary),
              tooltip: 'Members',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CallParticipantsScreen(call: call),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (call == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Participants area
              Expanded(child: ParticipantsGrid(call: call)),
              // Custom controls
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
      isHost: true,
      isTransmitting: ptt.isTransmitting,
      audioLevel: ptt.audioLevel,
      onPttDown: () => ref.read(pttStateProvider.notifier).startTransmitting(),
      onPttUp: () => ref.read(pttStateProvider.notifier).stopTransmitting(),
      onEndOrLeave: () async {
        await ref.read(pttStateProvider.notifier).stopTransmitting();
        await ref.read(roomSessionProvider.notifier).endRoom();
        if (context.mounted) context.go('/home');
      },
    );
  }
}

class _PreCallHostView extends ConsumerWidget {
  final String roomId;

  const _PreCallHostView({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.spatial_audio_rounded,
            size: 64,
            color: AppColors.accent,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to start?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Participants will be able to join once you start.',
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
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Room', style: TextStyle(fontSize: 16)),
              onPressed: () =>
                  ref.read(roomSessionProvider.notifier).startRoomAndEnter(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Room', style: TextStyle(fontSize: 16)),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      'Delete Room',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    content: const Text(
                      'This will permanently delete the room.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(roomSessionProvider.notifier).deleteRoom();
                  if (context.mounted) context.go('/home');
                }
              },
            ),
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

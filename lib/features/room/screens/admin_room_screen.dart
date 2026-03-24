import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import '../providers/getstream_provider.dart';
import '../providers/room_session_provider.dart';
import '../providers/room_participants_provider.dart';
import '../providers/ptt_provider.dart';
import '../widgets/ptt_button.dart';
import '../widgets/ptt_waveform.dart';
import '../widgets/room_header.dart';
import '../widgets/member_tile.dart';
import '../widgets/member_controls_sheet.dart';
import '../widgets/admin_action_bar.dart';
import '../../../domain/enums/room_status.dart';
import '../../../shared/widgets/connection_status_bar.dart';
import '../../../shared/animations/pulse_animation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';

class AdminRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const AdminRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<AdminRoomScreen> createState() => _AdminRoomScreenState();
}

class _AdminRoomScreenState extends ConsumerState<AdminRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(roomSessionProvider);
    final pttState = ref.watch(pttStateProvider);

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
                  onCancelCallTap: () async {
                    await call.end();
                  },
                  callContentWidgetBuilder: (context, call) {
                    return StreamCallContent(
                      call: call,
                      // callAppBarWidgetBuilder: (context, call) {
                      //   return CallAppBar(
                      //     call: call,
                      //     // leadingWidth: 120,
                      //     // leading: Row(
                      //     //   children: [
                      //     //     ToggleLayoutOption(
                      //     //       onLayoutModeChanged: (layout) {
                      //     //         // setState(() {
                      //     //         //   _currentLayoutMode = layout;
                      //     //         // });
                      //     //       },
                      //     //     ),
                      //     //     PartialCallStateBuilder(
                      //     //       call: call,
                      //     //       selector: (state) =>
                      //     //           state.localParticipant != null,
                      //     //       builder: (context, hasLocalParticipant) =>
                      //     //           hasLocalParticipant
                      //     //           ? FlipCameraOption(call: call)
                      //     //           : const SizedBox.shrink(),
                      //     //     ),
                      //     //   ],
                      //     // ),
                      //     // title: CallDurationTitle(call: call),
                      //   );
                      // },
                      callParticipantsWidgetBuilder:
                          (BuildContext context, Call call) {
                            return StreamCallParticipants(
                              call: call,
                              layoutMode: ParticipantLayoutMode.grid,
                            );
                          },
                      // callParticipantsWidgetBuilder: (context, call) {
                      //   return StreamBuilder<CallState>(
                      //     stream: call.state.valueStream,
                      //     initialData: call.state.value,
                      //     builder: (context, snapshot) {
                      //       final participants =
                      //           snapshot.data?.callParticipants ?? [];
                      //       if (participants.isEmpty) {
                      //         return const Center(
                      //           child: Text(
                      //             'Waiting for participants...',
                      //             style: TextStyle(
                      //               color: AppColors.textSecondary,
                      //             ),
                      //           ),
                      //         );
                      //       }
                      //       return ListView.builder(
                      //         itemCount: participants.length,
                      //         itemBuilder: (context, i) {
                      //           final p = participants[i];
                      //           return ListTile(
                      //             leading: CircleAvatar(
                      //               backgroundColor: AppColors.accent,
                      //               child: Text(
                      //                 (p.name.isNotEmpty ? p.name : p.userId)[0]
                      //                     .toUpperCase(),
                      //                 style: const TextStyle(
                      //                   color: Colors.white,
                      //                 ),
                      //               ),
                      //             ),
                      //             title: Text(
                      //               p.name.isNotEmpty ? p.name : p.userId,
                      //               style: const TextStyle(
                      //                 color: AppColors.textPrimary,
                      //               ),
                      //             ),
                      //             trailing: Icon(
                      //               p.isAudioEnabled
                      //                   ? Icons.mic
                      //                   : Icons.mic_off,
                      //               color: p.isAudioEnabled
                      //                   ? AppColors.accent
                      //                   : AppColors.textHint,
                      //             ),
                      //           );
                      //         },
                      //       );
                      //     },
                      //   );
                      // },
                      callControlsWidgetBuilder: (context, call) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.call_end_rounded),
                              label: const Text('Leave'),
                              onPressed: () => call.end(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            //   const ConnectionStatusBar(),
            //   sessionAsync.when(
            //     loading: () => const SizedBox.shrink(),
            //     error: (_, _) => const SizedBox.shrink(),
            //     data: (session) =>
            //         RoomHeader(roomId: widget.roomId, roomName: session.roomName),
            //   ),
            //   Expanded(
            //     child: sessionAsync.when(
            //       loading: () => const Center(child: CircularProgressIndicator()),
            //       error: (e, _) => Center(
            //         child: Text(
            //           mapErrorToMessage(e),
            //           style: const TextStyle(color: AppColors.error),
            //         ),
            //       ),
            //       data: (session) => switch ((session.isInCall, session.status)) {
            //         (true, _) => _LiveHostView(
            //           roomId: widget.roomId,
            //           pttState: pttState,
            //         ),
            //         (false, RoomStatus.active) => _PreCallHostView(
            //           roomId: widget.roomId,
            //         ),
            //         (false, RoomStatus.inactive) => const _DisabledView(),
            //         (false, RoomStatus.ended) => const _DisabledView(
            //           message: 'This room has ended.',
            //         ),
            //         _ => const SizedBox.shrink(),
            //       },
            //     ),
            //   ),
            //   // Action bar + leave button only shown when in call
            //   sessionAsync.maybeWhen(
            //     data: (session) => session.isInCall
            //         ? Column(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               const AdminActionBar(),
            //               Padding(
            //                 padding: const EdgeInsets.symmetric(
            //                   horizontal: 24,
            //                   vertical: 12,
            //                 ),
            //                 child: SizedBox(
            //                   width: double.infinity,
            //                   child: OutlinedButton.icon(
            //                     style: OutlinedButton.styleFrom(
            //                       foregroundColor: AppColors.error,
            //                       side: const BorderSide(color: AppColors.error),
            //                     ),
            //                     icon: const Icon(Icons.call_end_rounded),
            //                     label: const Text('Leave Room'),
            //                     onPressed: () async {
            //                       await ref
            //                           .read(pttStateProvider.notifier)
            //                           .stopTransmitting();
            //                       await ref
            //                           .read(roomSessionProvider.notifier)
            //                           .leaveRoom();
            //                       if (context.mounted) context.go('/home');
            //                     },
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           )
            //         : const SizedBox.shrink(),
            //     orElse: () => const SizedBox.shrink(),
            //   ),
          ],
        ),
      ),
    );
  }
}

class CallDurationTitle extends StatefulWidget {
  const CallDurationTitle({super.key, required this.call});

  final Call call;

  @override
  State<CallDurationTitle> createState() => _CallDurationTitleState();
}

class _CallDurationTitleState extends State<CallDurationTitle> {
  @override
  Widget build(BuildContext context) {
    final videoTheme = StreamVideoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: videoTheme.callControlsTheme.optionBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: StreamBuilder<Duration>(
        stream: widget.call.callDurationStream,
        builder: (context, snapshot) {
          final duration = snapshot.data ?? Duration.zero;

          return RichText(
            text: TextSpan(
              text: duration.inMinutes.toString().padLeft(2, '0'),
              style: videoTheme.textTheme.bodyBold.copyWith(
                color: AppColors.surface,
              ),
              children: <TextSpan>[
                TextSpan(
                  text:
                      ':${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiveHostView extends ConsumerWidget {
  final String roomId;
  final dynamic pttState;

  const _LiveHostView({required this.roomId, required this.pttState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));
    // Cross-reference GetStream mute state for online members
    final muteByUserId =
        ref.watch(roomSessionProvider).asData?.value.members != null
        ? {
            for (final m
                in ref.watch(roomSessionProvider).asData!.value.members)
              m.userId: m.isMuted,
          }
        : <String, bool>{};

    return participantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final sorted = [...data.allMembers]
          ..sort((a, b) {
            final aOnline = data.isOnline(a.userId) ? 0 : 1;
            final bOnline = data.isOnline(b.userId) ? 0 : 1;
            return aOnline.compareTo(bOnline);
          });

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final member = sorted[i];
                  final isOnline = data.isOnline(member.userId);
                  final memberWithMute = member.copyWith(
                    isMuted: muteByUserId[member.userId] ?? member.isMuted,
                  );
                  return MemberTile(
                    member: memberWithMute,
                    isOnline: isOnline,
                    onTap: isOnline
                        ? () => showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) =>
                                MemberControlsSheet(member: memberWithMute),
                          )
                        : null,
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * i),
                    duration: const Duration(milliseconds: 300),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: PulseAnimation(
                isActive: pttState.isTransmitting,
                color: AppColors.accent,
                child: const PttButton(),
              ),
            ),
            const PttWaveform(),
            const SizedBox(height: 8),
          ],
        );
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

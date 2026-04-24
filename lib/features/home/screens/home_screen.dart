import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/rooms_provider.dart';
import '../widgets/room_card.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_by_id_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/connection_status_bar.dart';
import '../../shell/widgets/floating_pill_navbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/enums/room_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/widgets/web_max_width.dart';
import '../../room/providers/getstream_provider.dart';
import '../../room/providers/room_session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final authState = ref.watch(authStateProvider);
    final user = switch (authState) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: _AppBarTitle(name: user?.name, role: user?.role),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(roomsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: WebMaxWidth(
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ConnectionStatusBar(),
            Expanded(
              child: roomsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mapErrorToMessage(e),
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(roomsProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text(
                        'No rooms yet',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      FloatingPillNavBar.bottomPadding(context) + 8,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, i) => RoomCard(
                      room: rooms[i],
                      animationIndex: i,
                      onTap: () {
                        final room = rooms[i];
                        final activeCall = ref.read(activeCallProvider);
                        final activeSession = ref
                            .read(roomSessionProvider)
                            .value;
                        if (activeCall != null &&
                            activeSession != null &&
                            activeSession.isInCall &&
                            activeSession.roomId != room.roomId) {
                          AppSnackBar.show(
                            context,
                            message:
                                'You are already in "${activeSession.roomName}". Leave it first.',
                            actionLabel: 'Go back',
                            onAction: () => context.push(
                              '/room/${activeSession.roomId}',
                            ),
                          );
                          return;
                        }

                        // Block normal users from entering non-live rooms
                        if (user?.role == UserRole.user &&
                            room.status != RoomStatus.live) {
                          final msg = switch (room.status) {
                            RoomStatus.active =>
                              'Room is not live yet. Waiting for the host to start.',
                            RoomStatus.inactive =>
                              'This room has been disabled by admin.',
                            RoomStatus.ended => 'This room has ended.',
                            RoomStatus.live => '', // unreachable
                          };
                          AppSnackBar.show(context, message: msg);
                          return;
                        }

                        context.push('/room/${room.roomId}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
      // floatingActionButton: user?.role == UserRole.host
      //     ? FloatingActionButton.extended(
      //         backgroundColor: AppColors.accent,
      //         foregroundColor: Colors.white,
      //         onPressed: () {
      //           showModalBottomSheet(
      //             context: context,
      //             isScrollControlled: true,
      //             backgroundColor: AppColors.surface,
      //             shape: const RoundedRectangleBorder(
      //               borderRadius: BorderRadius.vertical(
      //                 top: Radius.circular(20),
      //               ),
      //             ),
      //             builder: (_) => const CreateRoomSheet(),
      //           );
      //         },
      //         icon: const Icon(Icons.add_rounded),
      //         label: const Text('Create Room'),
      //       )
      //     : FloatingActionButton.extended(
      //         backgroundColor: AppColors.accent,
      //         foregroundColor: Colors.white,
      //         onPressed: () {
      //           showModalBottomSheet(
      //             context: context,
      //             isScrollControlled: true,
      //             backgroundColor: AppColors.surface,
      //             shape: const RoundedRectangleBorder(
      //               borderRadius: BorderRadius.vertical(
      //                 top: Radius.circular(20),
      //               ),
      //             ),
      //             builder: (_) => const JoinByIdSheet(),
      //           );
      //         },
      //         icon: const Icon(Icons.login_rounded),
      //         label: const Text('Join Room'),
      //       ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final String? name;
  final UserRole? role;

  const _AppBarTitle({this.name, this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('My Rooms'),
        if (role != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: role == UserRole.host
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.textHint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: role == UserRole.host
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.textHint.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              role == UserRole.host ? 'Host' : 'Member',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: role == UserRole.host
                    ? AppColors.accent
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

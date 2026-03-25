import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/rooms_provider.dart';
import '../widgets/room_card.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_by_id_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/connection_status_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/enums/user_role.dart';

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ConnectionStatusBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: AppColors.background,
                    pinned: true,
                    title: _AppBarTitle(name: user?.name, role: user?.role),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                        onPressed: () =>
                            ref.read(roomsProvider.notifier).refresh(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () async {
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                  roomsAsync.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: Center(
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
                    ),
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No rooms yet',
                              style: TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => RoomCard(
                              room: rooms[i],
                              animationIndex: i,
                              onTap: () => {
                                context.push('/room/${rooms[i].roomId}'),
                              },
                            ),
                            childCount: rooms.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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

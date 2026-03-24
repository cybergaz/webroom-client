import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_participants_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/user_role.dart';
import '../../../features/auth/providers/auth_provider.dart';

class RoomHeader extends ConsumerWidget {
  final String roomId;
  final String roomName;

  const RoomHeader({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isHost = switch (authState) {
      AuthStateAuthenticated(:final user) => user.role == UserRole.host,
      _ => false,
    };

    return isHost
        ? _HostHeader(roomId: roomId, roomName: roomName)
        : _UserHeader(roomName: roomName);
  }
}

class _HostHeader extends ConsumerWidget {
  final String roomId;
  final String roomName;

  const _HostHeader({required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));

    final subtitle = participantsAsync.when(
      loading: () => const Text(
        'Loading members...',
        style: TextStyle(color: AppColors.textHint, fontSize: 12),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) => Row(
        children: [
          Text(
            '${data.totalCount} members',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (data.onlineCount > 0) ...[
            const Text(
              '  ·  ',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '${data.onlineCount} online',
              style: const TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/room/$roomId/members'),
      child: _HeaderShell(
        roomName: roomName,
        subtitle: subtitle,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
          size: 20,
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String roomName;

  const _UserHeader({required this.roomName});

  @override
  Widget build(BuildContext context) {
    return _HeaderShell(roomName: roomName);
  }
}

class _HeaderShell extends StatelessWidget {
  final String roomName;
  final Widget? subtitle;
  final Widget? trailing;

  const _HeaderShell({required this.roomName, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spatial_audio_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  subtitle!,
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

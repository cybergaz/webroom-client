import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_session_provider.dart';
import '../../../data/models/room_member_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../core/network/dio_client.dart';

class MemberControlsSheet extends ConsumerWidget {
  final RoomMemberModel member;

  const MemberControlsSheet({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              member.isMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: AppColors.accent,
            ),
            title: Text(
              member.isMuted ? 'Unmute' : 'Mute',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(roomSessionProvider.notifier).muteMember(member.userId, !member.isMuted);
            },
          ),
          const Divider(color: AppColors.divider),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Force Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              final repo = UserRepositoryImpl(UserRemoteDatasource(ref.read(dioClientProvider)));
              await repo.forceLogout(member.userId);
            },
          ),
        ],
      ),
    );
  }
}

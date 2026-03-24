import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_participants_provider.dart';
import '../../../data/models/room_member_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';

class RoomMembersScreen extends ConsumerWidget {
  final String roomId;

  const RoomMembersScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: participantsAsync.maybeWhen(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Members'),
              Text(
                '${data.totalCount} assigned · ${data.onlineCount} in room',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          orElse: () => const Text('Members'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(roomParticipantsProvider(roomId)),
          ),
        ],
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mapErrorToMessage(e), style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(roomParticipantsProvider(roomId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.allMembers.isEmpty) {
            return const Center(
              child: Text(
                'No members assigned to this room.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Sort: online first, then offline
          final sorted = [...data.allMembers]
            ..sort((a, b) {
              final aOnline = data.isOnline(a.userId) ? 0 : 1;
              final bOnline = data.isOnline(b.userId) ? 0 : 1;
              return aOnline.compareTo(bOnline);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const Divider(
              color: AppColors.divider,
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, i) {
              final member = sorted[i];
              final isOnline = data.isOnline(member.userId);
              return _MemberTile(member: member, isOnline: isOnline);
            },
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomMemberModel member;
  final bool isOnline;

  const _MemberTile({required this.member, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textHint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        member.name,
        style: TextStyle(
          color: isOnline ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isOnline
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'In Room',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

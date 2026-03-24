import 'package:flutter/material.dart';
import '../../../data/models/room_member_model.dart';
import '../../../core/theme/app_colors.dart';

class MemberTile extends StatelessWidget {
  final RoomMemberModel member;
  final bool isOnline;
  final VoidCallback? onTap;

  const MemberTile({
    super.key,
    required this.member,
    this.isOnline = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: isOnline
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.textHint.withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: isOnline ? AppColors.accent : AppColors.textHint,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textHint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        member.name,
        style: TextStyle(
          color: isOnline ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isOnline ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        member.role,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: isOnline
          ? Icon(
              member.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: member.isMuted ? AppColors.error : AppColors.success,
              size: 20,
            )
          : const Text(
              'offline',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
    );
  }
}

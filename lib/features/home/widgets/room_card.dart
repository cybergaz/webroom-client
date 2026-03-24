import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/room_model.dart';
import '../../../domain/enums/room_status.dart';
import '../../../core/theme/app_colors.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final int animationIndex;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.animationIndex = 0,
  });

  Color _statusColor(RoomStatus status) => switch (status) {
    RoomStatus.live => AppColors.success,
    RoomStatus.active => AppColors.warning,
    RoomStatus.inactive || RoomStatus.ended => AppColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.spatial_audio_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor(room.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              room.status.name,
                              style: TextStyle(
                                color: _statusColor(room.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            // const SizedBox(width: 4),
                            // Text(
                            //   '${room.memberCount}',
                            //   style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * animationIndex),
          duration: 300.ms,
        )
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}

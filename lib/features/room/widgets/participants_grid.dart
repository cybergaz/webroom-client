import 'package:flutter/material.dart';
import 'package:stream_video/stream_video.dart';

import '../../../core/theme/app_colors.dart';

class ParticipantsGrid extends StatelessWidget {
  final Call call;

  const ParticipantsGrid({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallState>(
      stream: call.state.valueStream,
      initialData: call.state.valueOrNull,
      builder: (context, snapshot) {
        final participants = snapshot.data?.callParticipants ?? [];

        if (participants.isEmpty) {
          return const Center(
            child: Text(
              'Waiting for participants...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Phone: 3 cols, tablet: 4-5, desktop: 6+
            final crossAxisCount = width < 400
                ? 3
                : width < 600
                    ? 4
                    : width < 900
                        ? 5
                        : (width ~/ 140).clamp(6, 10);

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: participants.length,
              itemBuilder: (context, i) =>
                  _ParticipantTile(participant: participants[i]),
            );
          },
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipantState participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final name =
        participant.name.isNotEmpty ? participant.name : participant.userId;
    final speaking = participant.isSpeaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: speaking ? AppColors.success : AppColors.cardBorder,
          width: speaking ? 2 : 1,
        ),
        boxShadow: speaking
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                speaking ? AppColors.success.withValues(alpha: 0.2) : AppColors.accent.withValues(alpha: 0.2),
            backgroundImage:
                participant.image != null && participant.image!.isNotEmpty
                    ? NetworkImage(participant.image!)
                    : null,
            child: participant.image == null || participant.image!.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: speaking ? AppColors.success : AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
            size: 16,
            color: participant.isAudioEnabled
                ? AppColors.accent
                : AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:stream_video/stream_video.dart';

import '../../../core/theme/app_colors.dart';

class ParticipantsGrid extends StatefulWidget {
  final Call call;
  final bool hostOnly;
  final bool excludeLocal;

  const ParticipantsGrid({
    super.key,
    required this.call,
    this.hostOnly = false,
    this.excludeLocal = false,
  });

  @override
  State<ParticipantsGrid> createState() => _ParticipantsGridState();
}

class _ParticipantsGridState extends State<ParticipantsGrid> {
  // userId → when they last started speaking
  final Map<String, DateTime> _lastSpokeAt = {};

  void _updateSpeakingTimes(List<CallParticipantState> participants) {
    final now = DateTime.now();
    for (final p in participants) {
      if (p.isSpeaking) {
        _lastSpokeAt[p.userId] = now;
      }
    }
  }

  List<CallParticipantState> _sorted(List<CallParticipantState> participants) {
    final list = [...participants];
    list.sort((a, b) {
      final aTime = _lastSpokeAt[a.userId];
      final bTime = _lastSpokeAt[b.userId];
      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallState>(
      stream: widget.call.state.valueStream,
      initialData: widget.call.state.valueOrNull,
      builder: (context, snapshot) {
        var participants = snapshot.data?.callParticipants ?? [];
        if (widget.hostOnly) {
          participants = participants
              .where((p) => p.roles.contains('host'))
              .toList();
        }
        if (widget.excludeLocal) {
          participants = participants.where((p) => !p.isLocal).toList();
        }

        _updateSpeakingTimes(participants);
        participants = _sorted(participants);

        if (participants.isEmpty) {
          return Center(
            child: Text(
              widget.excludeLocal
                  ? "You're the only one here"
                  : 'Waiting for participants...',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        if (widget.hostOnly) {
          if (participants.length == 1) {
            return _FullScreenParticipantTile(participant: participants.first);
          }
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final p in participants)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 120,
                      height: 140,
                      child: _ParticipantTile(participant: p),
                    ),
                  ),
              ],
            ),
          );
        }

        if (participants.length == 1) {
          return _FullScreenParticipantTile(participant: participants.first);
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

            final aspectRatio = width < 400
                ? 0.9
                : width < 600
                ? 0.8
                : width < 900
                ? 1.0
                : 1.8;

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: aspectRatio,
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

class _FullScreenParticipantTile extends StatelessWidget {
  final CallParticipantState participant;

  const _FullScreenParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final name = participant.name.isNotEmpty
        ? participant.name
        : participant.userId;
    final speaking = participant.isSpeaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: speaking ? AppColors.success : AppColors.cardBorder,
          width: speaking ? 3 : 1,
        ),
        boxShadow: speaking
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              color: speaking ? AppColors.success : AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Icon(
            participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
            size: 28,
            color: participant.isAudioEnabled
                ? AppColors.accent
                : AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipantState participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final name = participant.name.isNotEmpty
        ? participant.name
        : participant.userId;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              style: TextStyle(
                color: speaking ? AppColors.success : AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            participant.isAudioEnabled ? Icons.mic : Icons.mic_off,
            size: 18,
            color: participant.isAudioEnabled
                ? AppColors.accent
                : AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

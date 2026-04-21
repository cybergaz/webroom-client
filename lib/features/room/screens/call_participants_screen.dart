import 'package:flutter/material.dart';
import 'package:stream_video/stream_video.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';

/// Full-screen participant list with host moderation controls
/// (mute, kick, block).
class CallParticipantsScreen extends StatelessWidget {
  final Call call;

  const CallParticipantsScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: StreamBuilder<CallState>(
          stream: call.state.valueStream,
          initialData: call.state.valueOrNull,
          builder: (context, snap) {
            final count = _dedupeByUserId(
              snap.data?.callParticipants ?? const [],
            ).length;
            return Text('Participants ($count)');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_off_rounded),
            tooltip: 'Mute All',
            onPressed: () async {
              await call.muteAllUsers();
              if (context.mounted) {
                AppSnackBar.show(
                  context,
                  message: 'All participants muted',
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<CallState>(
        stream: call.state.valueStream,
        initialData: call.state.valueOrNull,
        builder: (context, snapshot) {
          final participants = _dedupeByUserId(
            snapshot.data?.callParticipants ?? const [],
          );
          if (participants.isEmpty) {
            return const Center(
              child: Text(
                'No participants yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Sort: local first, then by name
          final sorted = [...participants]..sort((a, b) {
              if (a.isLocal && !b.isLocal) return -1;
              if (!a.isLocal && b.isLocal) return 1;
              return a.name.compareTo(b.name);
            });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              return _ParticipantTile(
                participant: sorted[i],
                call: call,
              );
            },
          );
        },
      ),
    );
  }
}

// A force-killed client's SFU session lingers until Stream's timeout fires,
// so the same userId can appear under two sessionIds. Keep the live one.
List<CallParticipantState> _dedupeByUserId(
  List<CallParticipantState> participants,
) {
  int liveness(CallParticipantState p) {
    var score = 0;
    if (p.isOnline) score += 1000;
    score += p.publishedTracks.length * 10;
    score += p.connectionQuality.index;
    return score;
  }

  final byUser = <String, CallParticipantState>{};
  for (final p in participants) {
    final existing = byUser[p.userId];
    if (existing == null || liveness(p) > liveness(existing)) {
      byUser[p.userId] = p;
    }
  }
  return byUser.values.toList();
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipantState participant;
  final Call call;

  const _ParticipantTile({required this.participant, required this.call});

  @override
  Widget build(BuildContext context) {
    final displayName = participant.name.isNotEmpty
        ? participant.name
        : participant.userId;
    final isHost = participant.roles.contains('host') ||
        participant.roles.contains('admin');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isHost ? AppColors.accent : AppColors.surfaceVariant,
        backgroundImage: participant.image != null &&
                participant.image!.isNotEmpty
            ? NetworkImage(participant.image!)
            : null,
        child:
            participant.image == null || participant.image!.isEmpty
                ? Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (participant.isLocal) ...[
            const SizedBox(width: 6),
            const Text(
              '(You)',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
          if (isHost) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: participant.isSpeaking
          ? const Text(
              'Speaking...',
              style: TextStyle(color: AppColors.success, fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            participant.isAudioEnabled
                ? Icons.mic_rounded
                : Icons.mic_off_rounded,
            color: participant.isAudioEnabled
                ? AppColors.accent
                : AppColors.textHint,
            size: 20,
          ),
          // No actions for the local user
          if (!participant.isLocal) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              color: AppColors.surface,
              onSelected: (action) => _onAction(context, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'mute',
                  child: _MenuRow(
                    icon: Icons.mic_off_rounded,
                    label: 'Mute',
                    color: AppColors.textSecondary,
                  ),
                ),
                const PopupMenuItem(
                  value: 'kick',
                  child: _MenuRow(
                    icon: Icons.logout_rounded,
                    label: 'Kick',
                    color: AppColors.warning,
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: _MenuRow(
                    icon: Icons.block_rounded,
                    label: 'Block',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    final name = participant.name.isNotEmpty
        ? participant.name
        : participant.userId;

    switch (action) {
      case 'mute':
        await call.muteUsers(userIds: [participant.userId]);
        if (context.mounted) {
          AppSnackBar.show(context, message: '$name muted');
        }

      case 'kick':
        final ok = await _confirm(
          context,
          title: 'Kick User',
          body: 'Remove $name from the call?',
          action: 'Kick',
          actionColor: AppColors.warning,
        );
        if (ok) await call.kickUser(participant.userId);

      case 'block':
        final ok = await _confirm(
          context,
          title: 'Block User',
          body: "Block $name? They won't be able to rejoin.",
          action: 'Block',
          actionColor: AppColors.error,
        );
        if (ok) await call.blockUser(participant.userId);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Color actionColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:
            Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content:
            Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: TextStyle(color: actionColor)),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

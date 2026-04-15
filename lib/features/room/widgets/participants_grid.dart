import 'dart:async';

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
  // userId → timer that clears the active glow after silence
  final Map<String, Timer> _speakingTimers = {};

  static const _activeDuration = Duration(seconds: 6);

  void _updateSpeakingTimes(List<CallParticipantState> participants) {
    final now = DateTime.now();
    for (final p in participants) {
      if (p.isSpeaking) {
        _lastSpokeAt[p.userId] = now;
        _speakingTimers[p.userId]?.cancel();
        _speakingTimers[p.userId] = Timer(_activeDuration, () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  bool _isActive(CallParticipantState p) {
    if (p.isSpeaking) return true;
    final last = _lastSpokeAt[p.userId];
    if (last == null) return false;
    return DateTime.now().difference(last) < _activeDuration;
  }

  @override
  void dispose() {
    for (final t in _speakingTimers.values) {
      t.cancel();
    }
    super.dispose();
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
          participants =
              participants.where((p) => p.roles.contains('host')).toList();
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

        // ── hostOnly: existing compact row layout ───────────────────────
        if (widget.hostOnly) {
          if (participants.length == 1) {
            return _FullScreenParticipantTile(
              participant: participants.first,
              isActive: _isActive(participants.first),
            );
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
                      child: _ParticipantTile(
                        participant: p,
                        isActive: _isActive(p),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // ── Host view: split into active speakers / others ──────────────
        final active = participants.where(_isActive).toList();
        final rest = participants.where((p) => !_isActive(p)).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 400
                ? 3
                : width < 600
                    ? 4
                    : width < 900
                        ? 5
                        : (width ~/ 140).clamp(6, 10);
            final aspectRatio = width < 400
                ? 0.85
                : width < 600
                    ? 0.7
                    : width < 900
                        ? 0.85
                        : 1.5;

            final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: aspectRatio,
            );

            return CustomScrollView(
              slivers: [
                // ── Active Speakers ─────────────────────────────────────
                _sectionHeader('Active Speakers'),
                if (active.isEmpty)
                  const SliverToBoxAdapter(child: _QuietPlaceholder())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    sliver: SliverGrid(
                      gridDelegate: gridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ParticipantTile(
                          participant: active[i],
                          isActive: true,
                        ),
                        childCount: active.length,
                      ),
                    ),
                  ),

                // ── Divider ─────────────────────────────────────────────
                const SliverToBoxAdapter(child: _SectionDivider()),

                // ── Others ──────────────────────────────────────────────
                if (rest.isNotEmpty) ...[
                  _sectionHeader('Others'),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    sliver: SliverGrid(
                      gridDelegate: gridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ParticipantTile(
                          participant: rest[i],
                          isActive: false,
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static SliverToBoxAdapter _sectionHeader(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─── Section divider ─────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 4),
        Divider(color: AppColors.divider, thickness: 1, height: 1),
        SizedBox(height: 4),
      ],
    );
  }
}

// ─── Quiet placeholder ────────────────────────────────────────────────────────

class _QuietPlaceholder extends StatelessWidget {
  const _QuietPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        'No one is speaking',
        style: TextStyle(color: AppColors.textHint, fontSize: 13),
      ),
    );
  }
}

// ─── Full-screen tile (single participant) ────────────────────────────────────

class _FullScreenParticipantTile extends StatelessWidget {
  final CallParticipantState participant;
  final bool isActive;

  const _FullScreenParticipantTile({
    required this.participant,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        participant.name.isNotEmpty ? participant.name : participant.userId;
    final speaking = isActive;

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

// ─── Participant tile ─────────────────────────────────────────────────────────

class _ParticipantTile extends StatelessWidget {
  final CallParticipantState participant;
  final bool isActive;

  const _ParticipantTile({required this.participant, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final name =
        participant.name.isNotEmpty ? participant.name : participant.userId;
    final speaking = isActive;

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
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.clip,
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

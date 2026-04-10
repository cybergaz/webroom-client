import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/my_recording_model.dart';

class AudioPlayerSheet extends StatefulWidget {
  final MyRecording recording;
  final Future<String> Function() fetchUrl;

  const AudioPlayerSheet({
    super.key,
    required this.recording,
    required this.fetchUrl,
  });

  @override
  State<AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<AudioPlayerSheet> {
  final _player = AudioPlayer();
  final _subscriptions = <StreamSubscription>[];

  bool _fetchingUrl = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  ProcessingState _processingState = ProcessingState.idle;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }),
      _player.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      }),
      _player.playingStream.listen((playing) {
        if (mounted) setState(() => _playing = playing);
      }),
      _player.processingStateStream.listen((ps) {
        if (mounted) setState(() => _processingState = ps);
      }),
    ]);
    _init();
  }

  Future<void> _init() async {
    try {
      final url = await widget.fetchUrl();
      await _player.setUrl(url);
      if (mounted) setState(() => _fetchingUrl = false);
      await _player.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _fetchingUrl = false;
          _error = 'Failed to load recording';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_processingState == ProcessingState.completed) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recording info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic_rounded,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recording.roomName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(widget.recording.createdAt),
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (_fetchingUrl) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 12),
            const Text('Loading...',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
          ] else if (_error != null) ...[
            const SizedBox(height: 8),
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 14)),
            const SizedBox(height: 24),
          ] else ...[
            // Seek slider
            _SeekBar(
              position: _position,
              duration: _duration,
              onSeek: (pos) => _player.seek(pos),
            ),
            const SizedBox(height: 28),

            // Play / Pause / Replay button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: _processingState == ProcessingState.loading ||
                        _processingState == ProcessingState.buffering
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _processingState == ProcessingState.completed
                            ? Icons.replay_rounded
                            : (_playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month]} ${dt.day}, ${dt.year}  ·  $h:$m $period';
  }
}

// ─── Seek bar ─────────────────────────────────────────────────────────────────

class _SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _SeekBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _draggingValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final maxMs =
        widget.duration.inMilliseconds > 0 ? widget.duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = _draggingValue ??
        widget.position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.divider,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
            trackHeight: 3.5,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: currentMs,
            min: 0,
            max: maxMs,
            onChangeStart: (v) => setState(() => _draggingValue = v),
            onChanged: (v) => setState(() => _draggingValue = v),
            onChangeEnd: (v) {
              setState(() => _draggingValue = null);
              widget.onSeek(Duration(milliseconds: v.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(Duration(
                    milliseconds: (_draggingValue ?? currentMs).toInt())),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
              Text(
                _fmt(widget.duration),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

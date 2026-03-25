import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video/stream_video.dart';

import '../../../core/theme/app_colors.dart';

/// Custom call controls bar with mic toggle, audio output picker,
/// optional participants button (host), and end/leave.
class CallControlsBar extends StatefulWidget {
  final Call call;
  final bool isHost;
  final VoidCallback onEndOrLeave;
  final VoidCallback? onParticipantsTap;

  const CallControlsBar({
    super.key,
    required this.call,
    required this.isHost,
    required this.onEndOrLeave,
    this.onParticipantsTap,
  });

  @override
  State<CallControlsBar> createState() => _CallControlsBarState();
}

class _CallControlsBarState extends State<CallControlsBar> {
  final _deviceNotifier = RtcMediaDeviceNotifier.instance;
  StreamSubscription<List<RtcMediaDevice>>? _deviceSub;
  var _audioOutputs = <RtcMediaDevice>[];

  @override
  void initState() {
    super.initState();
    _deviceSub = _deviceNotifier.onDeviceChange.listen((devices) {
      if (!mounted) return;
      setState(() {
        _audioOutputs = devices
            .where((d) => d.kind == RtcMediaDeviceKind.audioOutput)
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallState>(
      stream: widget.call.state.valueStream,
      initialData: widget.call.state.valueOrNull,
      builder: (context, snapshot) {
        final callState = snapshot.data;
        final isMicOn =
            callState?.localParticipant?.isAudioEnabled ?? false;
        final currentOutputDevice = callState?.audioOutputDevice;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  label: isMicOn ? 'Mute' : 'Unmute',
                  isActive: isMicOn,
                  onTap: () =>
                      widget.call.setMicrophoneEnabled(enabled: !isMicOn),
                ),
                _ControlButton(
                  icon: _outputIcon(currentOutputDevice),
                  label: 'Speaker',
                  onTap: () => _showAudioOutputPicker(context),
                ),
                if (widget.isHost && widget.onParticipantsTap != null)
                  _ControlButton(
                    icon: Icons.people_rounded,
                    label: 'Members',
                    onTap: widget.onParticipantsTap,
                  ),
                _ControlButton(
                  icon: Icons.call_end_rounded,
                  label: widget.isHost ? 'End' : 'Leave',
                  isDestructive: true,
                  onTap: widget.onEndOrLeave,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _outputIcon(RtcMediaDevice? device) {
    if (device == null) return Icons.volume_up_rounded;
    final id = device.id.toLowerCase();
    if (id.contains('speaker')) return Icons.volume_up_rounded;
    if (id.contains('earpiece')) return Icons.hearing_rounded;
    if (id.contains('bluetooth')) return Icons.bluetooth_audio_rounded;
    if (id.contains('wired') || id.contains('headset')) {
      return Icons.headset_rounded;
    }
    return Icons.volume_up_rounded;
  }

  void _showAudioOutputPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final selected =
            widget.call.state.valueOrNull?.audioOutputDevice;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Audio Output',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_audioOutputs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No audio output devices found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ..._audioOutputs.map((device) {
                  final isActive = selected?.id == device.id;
                  return ListTile(
                    leading: Icon(
                      _outputIcon(device),
                      color: isActive
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      device.label.isNotEmpty ? device.label : device.id,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.accent)
                        : null,
                    onTap: () async {
                      await widget.call.setAudioOutputDevice(device);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (isDestructive) {
      bg = AppColors.error;
      fg = Colors.white;
    } else if (isActive) {
      bg = AppColors.accent;
      fg = Colors.white;
    } else {
      bg = AppColors.surfaceVariant;
      fg = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

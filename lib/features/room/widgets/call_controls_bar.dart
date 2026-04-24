import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video/stream_video.dart';

import '../../../core/theme/app_colors.dart';

/// Call controls bar with PTT button (user) or mute toggle (host) at center,
/// speaker picker, and end/leave.
class CallControlsBar extends StatefulWidget {
  final Call call;
  final bool isHost;
  final VoidCallback onEndOrLeave;

  // PTT callbacks (used by normal users)
  final VoidCallback? onPttDown;
  final VoidCallback? onPttUp;
  final bool isTransmitting;
  final double audioLevel;

  // Mute toggle (used by host)
  final VoidCallback? onMuteToggle;
  final bool isMuted;

  const CallControlsBar({
    super.key,
    required this.call,
    required this.isHost,
    required this.onEndOrLeave,
    this.onPttDown,
    this.onPttUp,
    this.isTransmitting = false,
    this.audioLevel = 0.0,
    this.onMuteToggle,
    this.isMuted = true,
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
        final currentOutputDevice = callState?.audioOutputDevice;

        return Container(
          padding: const EdgeInsets.only(top: 0, bottom: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: _outputIcon(currentOutputDevice),
                  label: 'Speaker',
                  onTap: () => _showAudioOutputPicker(context),
                ),
                Padding(
                  // when host, add more spacing around the mute toggle for better tap target
                  padding: EdgeInsets.symmetric(
                    vertical: widget.isHost ? 20 : 0,
                  ),
                  child: widget.isHost
                      ? _MuteToggleButton(
                          isMuted: widget.isMuted,
                          audioLevel: widget.audioLevel,
                          onTap: widget.onMuteToggle,
                        )
                      : _PttButton(
                          isTransmitting: widget.isTransmitting,
                          audioLevel: widget.audioLevel,
                          onPttDown: widget.onPttDown ?? () {},
                          onPttUp: widget.onPttUp ?? () {},
                        ),
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
        final selected = widget.call.state.valueOrNull?.audioOutputDevice;

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
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                          )
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

// ---------------------------------------------------------------------------
// Push-to-talk button with fluid animations
// ---------------------------------------------------------------------------

class _PttButton extends StatefulWidget {
  final bool isTransmitting;
  final double audioLevel;
  final VoidCallback onPttDown;
  final VoidCallback onPttUp;

  const _PttButton({
    required this.isTransmitting,
    required this.audioLevel,
    required this.onPttDown,
    required this.onPttUp,
  });

  @override
  State<_PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<_PttButton> with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _PttButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransmitting && !oldWidget.isTransmitting) {
      _pressController.forward();
      _pulseController.repeat();
    } else if (!widget.isTransmitting && oldWidget.isTransmitting) {
      _pressController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDown() {
    HapticFeedback.mediumImpact();
    widget.onPttDown();
  }

  void _onUp() {
    HapticFeedback.lightImpact();
    widget.onPttUp();
  }

  @override
  Widget build(BuildContext context) {
    const double baseSize = 90;
    // Audio-reactive ring expands 0–18px beyond the button
    final double levelRing = widget.audioLevel.clamp(0.0, 1.0) * 18;

    return SizedBox(
      width: baseSize + 40,
      height: baseSize + 40,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnim, _pulseAnim]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring (visible while transmitting)
              if (widget.isTransmitting) _buildPulseRing(baseSize),

              // Audio-level glow ring
              if (widget.isTransmitting)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: baseSize + levelRing,
                  height: baseSize + levelRing,
                  child: CustomPaint(
                    painter: _CircleRingPainter(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      strokeWidth: 3 + levelRing * 0.15,
                    ),
                  ),
                ),

              // Main button
              Transform.scale(scale: _scaleAnim.value, child: child),
            ],
          );
        },
        child: Listener(
          onPointerDown: (_) => _onDown(),
          onPointerUp: (_) => _onUp(),
          onPointerCancel: (_) => _onUp(),
          child: SizedBox(
            width: baseSize,
            height: baseSize,
            child: Material(
              animationDuration: const Duration(milliseconds: 200),
              color: widget.isTransmitting
                  ? AppColors.accent
                  : AppColors.surfaceVariant,
              shape: CircleBorder(
                side: BorderSide(
                  color: widget.isTransmitting
                      ? AppColors.accent
                      : AppColors.error.withValues(alpha: 0.5),
                  width: widget.isTransmitting ? 2.5 : 1.5,
                ),
              ),
              elevation: widget.isTransmitting ? 6 : 0,
              shadowColor: AppColors.accent.withValues(alpha: 0.45),
              child: Icon(
                widget.isTransmitting
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                color: widget.isTransmitting ? Colors.white : AppColors.error,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing(double baseSize) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final v = _pulseAnim.value;
        final size = baseSize + v * 36;
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CircleRingPainter(
              color: AppColors.accent.withValues(alpha: (1 - v) * 0.35),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Host mute/unmute toggle button
// ---------------------------------------------------------------------------

class _MuteToggleButton extends StatefulWidget {
  final bool isMuted;
  final double audioLevel;
  final VoidCallback? onTap;

  const _MuteToggleButton({
    required this.isMuted,
    this.audioLevel = 0.0,
    this.onTap,
  });

  @override
  State<_MuteToggleButton> createState() => _MuteToggleButtonState();
}

class _MuteToggleButtonState extends State<_MuteToggleButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (!widget.isMuted) {
      _pressController.value = 1.0;
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MuteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final transmitting = !widget.isMuted;
    final wasTransmitting = !oldWidget.isMuted;
    if (transmitting && !wasTransmitting) {
      _pressController.forward();
      _pulseController.repeat();
    } else if (!transmitting && wasTransmitting) {
      _pressController.reverse();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    const double baseSize = 90;
    final bool transmitting = !widget.isMuted;
    final double levelRing = widget.audioLevel.clamp(0.0, 1.0) * 18;

    return SizedBox(
      width: baseSize + 40,
      height: baseSize + 40,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnim, _pulseAnim]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (transmitting)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) {
                    final v = _pulseAnim.value;
                    final size = baseSize + v * 36;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: _CircleRingPainter(
                          color: AppColors.accent
                              .withValues(alpha: (1 - v) * 0.35),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              if (transmitting)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: baseSize + levelRing,
                  height: baseSize + levelRing,
                  child: CustomPaint(
                    painter: _CircleRingPainter(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      strokeWidth: 3 + levelRing * 0.15,
                    ),
                  ),
                ),
              Transform.scale(scale: _scaleAnim.value, child: child),
            ],
          );
        },
        child: GestureDetector(
          onTap: _onTap,
          child: SizedBox(
            width: baseSize,
            height: baseSize,
            child: Material(
              animationDuration: const Duration(milliseconds: 200),
              color: transmitting
                  ? AppColors.accent
                  : AppColors.surfaceVariant,
              shape: CircleBorder(
                side: BorderSide(
                  color: transmitting
                      ? AppColors.accent
                      : AppColors.error.withValues(alpha: 0.5),
                  width: transmitting ? 2.5 : 1.5,
                ),
              ),
              elevation: transmitting ? 6 : 0,
              shadowColor: AppColors.accent.withValues(alpha: 0.45),
              child: Icon(
                transmitting ? Icons.mic_rounded : Icons.mic_off_rounded,
                color: transmitting ? Colors.white : AppColors.error,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small control button (speaker, end/leave)
// ---------------------------------------------------------------------------

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isDestructive ? AppColors.error : AppColors.surfaceVariant;
    final Color fg = isDestructive ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Material(
              color: bg,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Icon(icon, color: fg, size: 24),
            ),
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

// ---------------------------------------------------------------------------
// Anti-aliased circle ring painter for pulse / audio-level rings
// ---------------------------------------------------------------------------

class _CircleRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CircleRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CircleRingPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

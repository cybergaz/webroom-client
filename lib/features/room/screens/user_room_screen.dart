import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_video/stream_video.dart';

import '../providers/getstream_provider.dart';
import '../providers/odds_provider.dart';
import '../providers/room_session_provider.dart';
import '../providers/ptt_provider.dart';
import '../widgets/market_odds_box.dart';
import '../widgets/odds_selection_dialog.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/error_mapper.dart';
import '../../auth/providers/auth_provider.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const UserRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  StreamSubscription? _wsSub;
  late final IsOnRoomScreenNotifier _roomScreenNotifier;
  late final OddsNotifier _oddsNotifier;
  Timer? _graceCountdownTimer;
  int _graceSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _roomScreenNotifier = ref.read(isOnRoomScreenProvider.notifier);
    _oddsNotifier = ref.read(oddsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roomScreenNotifier.set(true);
      ref.read(roomSessionProvider.notifier).loadRoom(widget.roomId);
      _subscribeToForceEvents();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      _roomScreenNotifier.set(false);
      _oddsNotifier.stopPolling();
    });
    _graceCountdownTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  void _subscribeToForceEvents() {
    final wsService = ref.read(websocketServiceProvider);
    final storage = ref.read(secureStorageProvider);

    _wsSub = wsService.events.listen((event) async {
      final eventName = event['event'] as String;
      final payload = event['payload'] as Map<String, dynamic>? ?? {};
      final myId = await storage.read(StorageKeys.userId);

      if (!mounted) return;

      if (eventName == 'room.member_kicked' &&
          payload['roomId'] == widget.roomId &&
          payload['userId'] == myId) {
        await ref.read(roomSessionProvider.notifier).leaveRoom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You were removed from the room')),
          );
          context.go('/home');
        }
      }

      if (eventName == 'user.force_logout' && payload['userId'] == myId) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    });
  }

  void _startGraceCountdown(int totalSeconds) {
    _graceCountdownTimer?.cancel();
    _graceSecondsRemaining = totalSeconds;
    _graceCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _graceCountdownTimer?.cancel();
        return;
      }
      setState(() {
        _graceSecondsRemaining = (_graceSecondsRemaining - 1).clamp(0, totalSeconds);
      });
    });
  }

  void _stopGraceCountdown() {
    _graceCountdownTimer?.cancel();
    if (mounted) setState(() => _graceSecondsRemaining = 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomSessionProvider, (prev, next) {
      next.when(
        data: (session) {
          if (session.isEnded && mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Room ended by host')));
            context.go('/home');
          }

          final wasDisconnected = prev?.value?.isHostDisconnected ?? false;
          if (session.isHostDisconnected && !wasDisconnected) {
            _startGraceCountdown(session.hostGraceSeconds);
          } else if (!session.isHostDisconnected && wasDisconnected) {
            _stopGraceCountdown();
          }
        },
        error: (e, _) {
          if (mounted) {
            final message = mapErrorToMessage(e);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 5),
              ),
            );
            context.go('/home');
          }
        },
        loading: () {},
      );
    });

    final call = ref.watch(activeCallProvider);
    final sessionState = ref.watch(roomSessionProvider);
    final roomName = sessionState.isLoading ? '' : (sessionState.value?.roomName ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          roomName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
            tooltip: 'Market Odds',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const OddsSelectionDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Host disconnection warning banner
            if (sessionState.value?.isHostDisconnected == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.warning,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Host disconnected. Room will end in ${_graceSecondsRemaining}s...',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const MarketOddsBox(),
            if (call == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(child: _UserCallView(call: call)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Root user call layout
// ---------------------------------------------------------------------------

class _UserCallView extends ConsumerWidget {
  final Call call;

  const _UserCallView({required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptt = ref.watch(pttStateProvider);

    return Column(
      children: [
        // Host display — upper half
        Expanded(
          flex: 5,
          child: _HostCard(call: call),
        ),
        // PTT button — lower half
        Expanded(
          flex: 5,
          child: _PttArea(
            isTransmitting: ptt.isTransmitting,
            audioLevel: ptt.audioLevel,
            onPttDown: () => ref.read(pttStateProvider.notifier).startTransmitting(),
            onPttUp: () => ref.read(pttStateProvider.notifier).stopTransmitting(),
          ),
        ),
        // Bottom controls
        _BottomControls(
          call: call,
          onLeave: () async {
            // Capture notifiers before navigation disposes the widget's ref
            final ptt = ref.read(pttStateProvider.notifier);
            final session = ref.read(roomSessionProvider.notifier);
            if (context.mounted) context.go('/home');
            await ptt.stopTransmitting();
            await session.leaveRoom();
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Host card
// ---------------------------------------------------------------------------

class _HostCard extends StatelessWidget {
  final Call call;

  const _HostCard({required this.call});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallState>(
      stream: call.state.valueStream,
      initialData: call.state.valueOrNull,
      builder: (context, snapshot) {
        final participants = snapshot.data?.callParticipants ?? [];
        final hostList = participants.where((p) => p.roles.contains('host')).toList();
        final host = hostList.isEmpty ? null : hostList.first;
        final speaking = host?.isSpeaking ?? false;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: speaking
                    ? AppColors.success.withValues(alpha: 0.55)
                    : AppColors.cardBorder,
                width: speaking ? 2 : 1,
              ),
              boxShadow: speaking
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: host == null ? const _WaitingHost() : _HostInfo(host: host),
          ),
        );
      },
    );
  }
}

class _WaitingHost extends StatelessWidget {
  const _WaitingHost();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textHint),
        ),
        SizedBox(height: 14),
        Text(
          'Connecting...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HostInfo extends StatelessWidget {
  final CallParticipantState host;

  const _HostInfo({required this.host});

  @override
  Widget build(BuildContext context) {
    final name = host.name.isNotEmpty ? host.name : host.userId;
    final speaking = host.isSpeaking;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar with speaking glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: speaking
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: 52,
            backgroundColor: speaking
                ? AppColors.success.withValues(alpha: 0.18)
                : AppColors.accent.withValues(alpha: 0.13),
            backgroundImage: host.image != null && host.image!.isNotEmpty
                ? NetworkImage(host.image!)
                : null,
            child: host.image == null || host.image!.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: speaking ? AppColors.success : AppColors.accent,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _StatusBadge(
            key: ValueKey(speaking),
            label: speaking ? 'Speaking' : 'Connected',
            color: speaking ? AppColors.success : AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PTT area
// ---------------------------------------------------------------------------

class _PttArea extends StatefulWidget {
  final bool isTransmitting;
  final double audioLevel;
  final VoidCallback onPttDown;
  final VoidCallback onPttUp;

  const _PttArea({
    required this.isTransmitting,
    required this.audioLevel,
    required this.onPttDown,
    required this.onPttUp,
  });

  @override
  State<_PttArea> createState() => _PttAreaState();
}

class _PttAreaState extends State<_PttArea> with TickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant _PttArea old) {
    super.didUpdateWidget(old);
    if (widget.isTransmitting && !old.isTransmitting) {
      _pressCtrl.forward();
      _pulseCtrl.repeat();
    } else if (!widget.isTransmitting && old.isTransmitting) {
      _pressCtrl.reverse();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double btnSize = 130;
    final double levelRing = widget.audioLevel.clamp(0.0, 1.0) * 22;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_scaleAnim, _pulseAnim]),
          builder: (context, child) {
            return SizedBox(
              width: btnSize + 64,
              height: btnSize + 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding pulse ring
                  if (widget.isTransmitting)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        final v = _pulseAnim.value;
                        final size = btnSize + v * 50;
                        return SizedBox(
                          width: size,
                          height: size,
                          child: CustomPaint(
                            painter: _RingPainter(
                              color: AppColors.accent.withValues(alpha: (1 - v) * 0.28),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      },
                    ),
                  // Audio-level reactive ring
                  if (widget.isTransmitting)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: btnSize + levelRing,
                      height: btnSize + levelRing,
                      child: CustomPaint(
                        painter: _RingPainter(
                          color: AppColors.accent.withValues(alpha: 0.48),
                          strokeWidth: 3.5 + levelRing * 0.12,
                        ),
                      ),
                    ),
                  // Main button
                  Transform.scale(scale: _scaleAnim.value, child: child),
                ],
              ),
            );
          },
          child: Listener(
            onPointerDown: (_) {
              HapticFeedback.mediumImpact();
              widget.onPttDown();
            },
            onPointerUp: (_) {
              HapticFeedback.lightImpact();
              widget.onPttUp();
            },
            onPointerCancel: (_) => widget.onPttUp(),
            child: SizedBox(
              width: btnSize,
              height: btnSize,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isTransmitting ? AppColors.accent : AppColors.surfaceVariant,
                  border: Border.all(
                    color: widget.isTransmitting ? AppColors.accentLight : AppColors.divider,
                    width: widget.isTransmitting ? 2.5 : 1.5,
                  ),
                  boxShadow: widget.isTransmitting
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isTransmitting ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: widget.isTransmitting ? Colors.white : AppColors.textSecondary,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.isTransmitting ? 'Talking...' : 'Hold to Talk',
            key: ValueKey(widget.isTransmitting),
            style: TextStyle(
              color: widget.isTransmitting ? AppColors.accent : AppColors.textHint,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom controls (speaker + leave)
// ---------------------------------------------------------------------------

class _BottomControls extends StatefulWidget {
  final Call call;
  final VoidCallback onLeave;

  const _BottomControls({required this.call, required this.onLeave});

  @override
  State<_BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<_BottomControls> {
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
        final outputDevice = snapshot.data?.audioOutputDevice;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CtrlBtn(
                  icon: _outputIcon(outputDevice),
                  label: 'Speaker',
                  onTap: () => _showAudioPicker(context),
                ),
                _CtrlBtn(
                  icon: Icons.call_end_rounded,
                  label: 'Leave',
                  isDestructive: true,
                  onTap: widget.onLeave,
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
    if (id.contains('wired') || id.contains('headset')) return Icons.headset_rounded;
    return Icons.volume_up_rounded;
  }

  void _showAudioPicker(BuildContext context) {
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
                      color: isActive ? AppColors.accent : AppColors.textSecondary,
                    ),
                    title: Text(
                      device.label.isNotEmpty ? device.label : device.id,
                      style: TextStyle(
                        color: isActive ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_rounded, color: AppColors.accent)
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

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _CtrlBtn({
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
            width: 56,
            height: 56,
            child: Material(
              color: bg,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Icon(icon, color: fg, size: 26),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter (pulse / audio-level rings)
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _RingPainter({required this.color, required this.strokeWidth});

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
  bool shouldRepaint(_RingPainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}

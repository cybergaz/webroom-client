import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ptt_provider.dart';
import '../../../core/theme/app_colors.dart';

class PttButton extends ConsumerStatefulWidget {
  const PttButton({super.key});

  @override
  ConsumerState<PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends ConsumerState<PttButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pttState = ref.watch(pttStateProvider);
    final pttNotifier = ref.read(pttStateProvider.notifier);

    if (pttState.isTransmitting) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    return GestureDetector(
      onTapDown: (_) => pttNotifier.startTransmitting(),
      onTapUp: (_) => pttNotifier.stopTransmitting(),
      onTapCancel: () => pttNotifier.stopTransmitting(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: pttState.isTransmitting ? 138 : 120,
        height: pttState.isTransmitting ? 138 : 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: pttState.isTransmitting
                ? [const Color(0xFF8B85FF), AppColors.accent]
                : [AppColors.accent, const Color(0xFF4A44CC)],
          ),
          boxShadow: pttState.isTransmitting
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pttState.isTransmitting ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 4),
            Text(
              pttState.isTransmitting ? 'Transmitting...' : 'Hold to Talk',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

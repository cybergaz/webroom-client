import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ptt_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:math' as math;

class PttWaveform extends ConsumerWidget {
  const PttWaveform({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pttState = ref.watch(pttStateProvider);

    return AnimatedOpacity(
      opacity: pttState.isTransmitting ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 48,
        width: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(7, (i) {
            final height = pttState.isTransmitting
                ? 8.0 + (pttState.audioLevel * 40 * math.sin((i + 1) * 0.5)).abs().clamp(4.0, 48.0)
                : 4.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

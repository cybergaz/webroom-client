import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/odds_models.dart';
import '../providers/odds_provider.dart';
import '../../../core/theme/app_colors.dart';

class MarketOddsBox extends ConsumerWidget {
  const MarketOddsBox({super.key});

  static const _backColor = Color(0xFF72BBEF);
  static const _layColor = Color(0xFFFAA9BA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oddsState = ref.watch(oddsProvider);

    if (!oddsState.hasActiveOdds) return const SizedBox.shrink();

    final odds = oddsState.odds!;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event name + LIVE badge + close
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    oddsState.selectedEventName ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (odds.inPlay)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: const Icon(Icons.close, color: AppColors.textHint),
                    onPressed: () =>
                        ref.read(oddsProvider.notifier).stopPolling(),
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 144, // 3 cells x 48px
                  child: Center(
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        color: _backColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 144,
                  child: Center(
                    child: Text(
                      'LAY',
                      style: TextStyle(
                        color: _layColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Runner rows
          for (final runner in odds.runners)
            _runnerRow(
              ref.read(oddsProvider.notifier).runnerName(runner.selectionId),
              runner,
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _runnerRow(String name, RunnerOdds runner) {
    final backs = _pad(runner.back, 3);
    final lays = _pad(runner.lay, 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Back: deepest -> best (best closest to center)
          _cell(backs[2]?.price, _backColor, 0.15),
          _cell(backs[1]?.price, _backColor, 0.22),
          _cell(backs[0]?.price, _backColor, 0.32),
          // Lay: best -> deepest (best closest to center)
          _cell(lays[0]?.price, _layColor, 0.32),
          _cell(lays[1]?.price, _layColor, 0.22),
          _cell(lays[2]?.price, _layColor, 0.15),
        ],
      ),
    );
  }

  List<PriceSize?> _pad(List<PriceSize> list, int count) {
    return List.generate(count, (i) => i < list.length ? list[i] : null);
  }

  Widget _cell(double? price, Color color, double opacity) {
    return Container(
      width: 46,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        price != null ? price.toStringAsFixed(2) : '-',
        style: TextStyle(
          color: price != null ? AppColors.textPrimary : AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

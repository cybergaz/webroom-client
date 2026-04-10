import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/my_recording_model.dart';
import '../providers/my_recordings_provider.dart';
import '../widgets/audio_player_sheet.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(recordingsNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final state = ref.read(recordingsNotifierProvider);
    final initial = isFrom
        ? (state.fromDate ?? DateTime.now().subtract(const Duration(days: 7)))
        : (state.toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.surfaceVariant,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;

    ref
        .read(recordingsNotifierProvider.notifier)
        .applyFilter(
          from: isFrom ? picked : state.fromDate,
          to: isFrom ? state.toDate : picked,
        );
  }

  void _openPlayer(MyRecording recording) {
    final dio = ref.read(dioClientProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioPlayerSheet(
        recording: recording,
        fetchUrl: () => fetchRecordingUrl(dio, recording.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingsNotifierProvider);
    final hasFilter = state.fromDate != null || state.toDate != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(recordingsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter bar ────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              spacing: 5,
              children: [
                Row(
                  children: [
                    _DateChip(
                      label: 'From',
                      date: state.fromDate,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                    const SizedBox(width: 8),
                    _DateChip(
                      label: 'To',
                      date: state.toDate,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (hasFilter) ...[
                      GestureDetector(
                        onTap: () => ref
                            .read(recordingsNotifierProvider.notifier)
                            .clearFilter(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: AppColors.error,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!state.isLoading)
                      Text(
                        '${state.total} recording${state.total == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ─── Content ───────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : state.error != null && state.recordings.isEmpty
                ? _ErrorView(
                    onRetry: () =>
                        ref.read(recordingsNotifierProvider.notifier).refresh(),
                  )
                : state.recordings.isEmpty
                ? const _EmptyView()
                : _RecordingsList(
                    scrollController: _scrollController,
                    recordings: state.recordings,
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    onTap: _openPlayer,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Date chip ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  String _fmtDate(DateTime dt) {
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
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isSet = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: isSet ? AppColors.accent : AppColors.textHint,
            ),
            const SizedBox(width: 5),
            Text(
              isSet ? '${label}: ${_fmtDate(date!)}' : label,
              style: TextStyle(
                color: isSet ? AppColors.accent : AppColors.textHint,
                fontSize: 12,
                fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recordings list ──────────────────────────────────────────────────────────

class _RecordingsList extends StatelessWidget {
  final ScrollController scrollController;
  final List<MyRecording> recordings;
  final bool isLoadingMore;
  final bool hasMore;
  final void Function(MyRecording) onTap;

  const _RecordingsList({
    required this.scrollController,
    required this.recordings,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(recordings);
    final itemCount = items.length + (isLoadingMore || hasMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i == items.length) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        return switch (items[i]) {
          _DayHeader(:final label) => _DayHeaderTile(label: label),
          _RoomHeader(:final name) => _RoomHeaderTile(name: name),
          _RecordingItem(:final recording) => _RecordingTile(
            recording: recording,
            onTap: () => onTap(recording),
          ),
        };
      },
    );
  }

  List<_ListItem> _buildItems(List<MyRecording> recs) {
    final items = <_ListItem>[];
    String? curDay;
    String? curRoom;

    for (final r in recs) {
      final day = _dayLabel(r.createdAt);
      if (day != curDay) {
        curDay = day;
        curRoom = null;
        items.add(_DayHeader(day));
      }
      if (r.roomName != curRoom) {
        curRoom = r.roomName;
        items.add(_RoomHeader(r.roomName));
      }
      items.add(_RecordingItem(r));
    }

    return items;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

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
      'Dec',
    ];
    return dt.year == now.year
        ? '${months[dt.month]} ${dt.day}'
        : '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ─── List item types ──────────────────────────────────────────────────────────

sealed class _ListItem {}

class _DayHeader extends _ListItem {
  final String label;
  _DayHeader(this.label);
}

class _RoomHeader extends _ListItem {
  final String name;
  _RoomHeader(this.name);
}

class _RecordingItem extends _ListItem {
  final MyRecording recording;
  _RecordingItem(this.recording);
}

// ─── Tile widgets ─────────────────────────────────────────────────────────────

class _DayHeaderTile extends StatelessWidget {
  final String label;
  const _DayHeaderTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RoomHeaderTile extends StatelessWidget {
  final String name;
  const _RoomHeaderTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            color: AppColors.accent,
            size: 13,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final MyRecording recording;
  final VoidCallback onTap;

  const _RecordingTile({required this.recording, required this.onTap});

  String _fmtDuration(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = (s % 60).toString().padLeft(2, '0');
    return m == 0 ? '${s}s' : '${m}m ${rem}s';
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtTime(recording.createdAt),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtDuration(recording.durationMs)}  ·  ${_fmtSize(recording.fileSizeBytes)}',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty / error views ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none_rounded, color: AppColors.textHint, size: 52),
          SizedBox(height: 12),
          Text(
            'No recordings found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Try changing the date filter',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load recordings',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

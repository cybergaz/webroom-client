import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/odds_provider.dart';
import '../../../core/theme/app_colors.dart';

class OddsSelectionDialog extends ConsumerStatefulWidget {
  const OddsSelectionDialog({super.key});

  @override
  ConsumerState<OddsSelectionDialog> createState() =>
      _OddsSelectionDialogState();
}

class _OddsSelectionDialogState extends ConsumerState<OddsSelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _viewingEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(oddsProvider.notifier).fetchCompetitions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oddsState = ref.watch(oddsProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  if (_viewingEvents)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewingEvents = false;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _viewingEvents
                          ? oddsState.selectedCompetitionName ?? 'Events'
                          : 'Competitions',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: _viewingEvents
                      ? 'Search events...'
                      : 'Search competitions...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            // Error
            if (oddsState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  oddsState.error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            // Content
            Expanded(
              child: _viewingEvents
                  ? _buildEventsList(oddsState)
                  : _buildCompetitionsList(oddsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionsList(OddsState oddsState) {
    if (oddsState.isLoadingCompetitions) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = oddsState.competitions
        .where(
          (c) =>
              _searchQuery.isEmpty ||
              c.name.toLowerCase().contains(_searchQuery),
        )
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No competitions found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final comp = filtered[index];
        return ListTile(
          dense: true,
          title: Text(
            comp.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20,
          ),
          onTap: () {
            ref.read(oddsProvider.notifier).fetchEvents(comp.id, comp.name);
            setState(() {
              _viewingEvents = true;
              _searchController.clear();
              _searchQuery = '';
            });
          },
        );
      },
    );
  }

  Widget _buildEventsList(OddsState oddsState) {
    if (oddsState.isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = oddsState.events
        .where(
          (e) =>
              _searchQuery.isEmpty ||
              e.name.toLowerCase().contains(_searchQuery),
        )
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No upcoming events',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final event = filtered[index];
        final isLoadingThis = oddsState.loadingEventId == event.id;
        return ListTile(
          dense: true,
          title: Text(
            event.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          subtitle: Text(
            _formatDate(event.openDate),
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          trailing: isLoadingThis
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
                ),
          onTap: oddsState.isLoadingMarket
              ? null
              : () async {
                  final success = await ref
                      .read(oddsProvider.notifier)
                      .selectEvent(event.id, event.name);
                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webroom_client/core/constants/app_constants.dart';

import '../models/odds_models.dart';

final _sportsDio = Dio(
  BaseOptions(
    baseUrl: AppConstants.sportsUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ),
);

class OddsState {
  final List<Competition> competitions;
  final List<SportEvent> events;
  final String? selectedCompetitionName;
  final String? selectedEventName;
  final String? marketId;
  final List<RunnerInfo> runners;
  final MarketOdds? odds;
  final bool isLoadingCompetitions;
  final bool isLoadingEvents;
  final String? loadingEventId;
  final bool isPolling;
  final String? lastFetchTime;
  final String? error;

  const OddsState({
    this.competitions = const [],
    this.events = const [],
    this.selectedCompetitionName,
    this.selectedEventName,
    this.marketId,
    this.runners = const [],
    this.odds,
    this.isLoadingCompetitions = false,
    this.isLoadingEvents = false,
    this.loadingEventId,
    this.isPolling = false,
    this.lastFetchTime,
    this.error,
  });

  OddsState copyWith({
    List<Competition>? competitions,
    List<SportEvent>? events,
    String? selectedCompetitionName,
    String? selectedEventName,
    String? marketId,
    List<RunnerInfo>? runners,
    MarketOdds? odds,
    bool? isLoadingCompetitions,
    bool? isLoadingEvents,
    String? loadingEventId,
    bool? isPolling,
    String? lastFetchTime,
    String? error,
    bool clearOdds = false,
    bool clearMarketId = false,
    bool clearLoadingEventId = false,
    bool clearEventName = false,
    bool clearCompetitionName = false,
    bool clearError = false,
  }) {
    return OddsState(
      competitions: competitions ?? this.competitions,
      events: events ?? this.events,
      selectedCompetitionName: clearCompetitionName
          ? null
          : (selectedCompetitionName ?? this.selectedCompetitionName),
      selectedEventName: clearEventName
          ? null
          : (selectedEventName ?? this.selectedEventName),
      marketId: clearMarketId ? null : (marketId ?? this.marketId),
      runners: runners ?? this.runners,
      odds: clearOdds ? null : (odds ?? this.odds),
      isLoadingCompetitions:
          isLoadingCompetitions ?? this.isLoadingCompetitions,
      isLoadingEvents: isLoadingEvents ?? this.isLoadingEvents,
      loadingEventId: clearLoadingEventId
          ? null
          : (loadingEventId ?? this.loadingEventId),
      isPolling: isPolling ?? this.isPolling,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoadingMarket => loadingEventId != null;

  bool get hasActiveOdds =>
      marketId != null && odds != null && runners.isNotEmpty;
}

class OddsNotifier extends Notifier<OddsState> {
  Timer? _pollTimer;

  @override
  OddsState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const OddsState();
  }

  Future<void> fetchCompetitions() async {
    state = state.copyWith(isLoadingCompetitions: true, clearError: true);
    try {
      final response = await Dio().get(AppConstants.aiexchcompetitionsUrl);
      final data = response.data as Map<String, dynamic>;
      final list = ((data['data'] as List<dynamic>?) ?? [])
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(competitions: list, isLoadingCompetitions: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingCompetitions: false,
        error: 'Failed to load competitions',
      );
    }
  }

  Future<void> fetchEvents(String competitionId, String competitionName) async {
    state = state.copyWith(
      isLoadingEvents: true,
      selectedCompetitionName: competitionName,
      events: [],
      clearError: true,
    );
    try {
      final response = await _sportsDio.get('/competitions/$competitionId');
      final data = response.data as Map<String, dynamic>;
      final eventsList = (data['events'] as List<dynamic>?) ?? [];
      final events =
          eventsList
              .map((e) => SportEvent.fromJson(e as Map<String, dynamic>))
              .where((e) => !e.isExpired)
              .toList()
            ..sort((a, b) => a.openDate.compareTo(b.openDate));
      state = state.copyWith(events: events, isLoadingEvents: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingEvents: false,
        error: 'Failed to load events',
      );
    }
  }

  Future<bool> selectEvent(String eventId, String eventName) async {
    _pollTimer?.cancel();
    state = state.copyWith(
      loadingEventId: eventId,
      selectedEventName: eventName,
      clearError: true,
      clearOdds: true,
    );
    try {
      // Get event details -> extract MATCH_ODDS market ID + runner names
      final eventResponse = await _sportsDio.get('/events/$eventId');
      final eventData = eventResponse.data as Map<String, dynamic>;
      final catalogues = (eventData['catalogues'] as List<dynamic>?) ?? [];
      print('[ODDS] eventId=$eventId catalogues=${catalogues.length}');

      String? matchOddsMarketId;
      List<RunnerInfo> runners = [];

      for (final cat in catalogues) {
        final catMap = cat as Map<String, dynamic>;
        print('[ODDS] catalogue marketType=${catMap['marketType']}');
        if (catMap['marketType'] == 'MATCH_ODDS') {
          matchOddsMarketId = catMap['marketId'] as String;
          // Runner names are already in the catalogue
          final runnersData = (catMap['runners'] as List<dynamic>?) ?? [];
          runners = runnersData.map((r) {
            final rm = r as Map<String, dynamic>;
            return RunnerInfo(
              selectionId: rm['id'] as int,
              name: rm['name'] as String? ?? 'Unknown',
            );
          }).toList();
          print(
            '[ODDS] found MATCH_ODDS marketId=$matchOddsMarketId runners=${runners.length}',
          );
          break;
        }
      }

      if (matchOddsMarketId == null || runners.isEmpty) {
        print(
          '[ODDS] no market data: marketId=$matchOddsMarketId runners=${runners.length}',
        );
        state = state.copyWith(
          clearLoadingEventId: true,
          error: 'No market data found',
        );
        return false;
      }

      state = state.copyWith(
        marketId: matchOddsMarketId,
        runners: runners,
        clearLoadingEventId: true,
      );

      // Start polling odds every 3 seconds
      _startPolling(matchOddsMarketId);
      print('[ODDS] polling started, hasActiveOdds=${state.hasActiveOdds}');
      return true;
    } catch (e) {
      print('[ODDS] selectEvent error: $e');
      state = state.copyWith(
        clearLoadingEventId: true,
        error: 'Failed to load market data',
      );
      return false;
    }
  }

  int _emptyFetchCount = 0;
  static const _maxEmptyFetches = 2;

  void _startPolling(String marketId) {
    _pollTimer?.cancel();
    _emptyFetchCount = 0;
    state = state.copyWith(isPolling: true);
    _fetchOdds(marketId);
    _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _fetchOdds(marketId);
    });
  }

  String _formatFetchTime() {
    final now = DateTime.now();
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$mm:$ss:$ms';
  }

  Future<void> _fetchOdds(String marketId) async {
    try {
      final fetchTime = _formatFetchTime();
      state = state.copyWith(lastFetchTime: fetchTime);
      final response = await _sportsDio.get('/books/$marketId');
      final data = response.data as Map<String, dynamic>;
      final marketData = data[marketId] as Map<String, dynamic>?;
      // print(
      //   '[ODDS] fetchOdds marketId=$marketId hasData=${marketData != null} runners=${marketData?['runners']?.length}',
      // );
      if (marketData != null) {
        _emptyFetchCount = 0;
        state = state.copyWith(odds: MarketOdds.fromJson(marketId, marketData));
        // print(
        //   '[ODDS] hasActiveOdds=${state.hasActiveOdds} odds.runners=${state.odds?.runners.length}',
        // );
      } else {
        _emptyFetchCount++;
        if (_emptyFetchCount >= _maxEmptyFetches) {
          print('[ODDS] giving up after $_maxEmptyFetches empty fetches');
          stopPolling();
          state = state.copyWith(error: 'No market data available');
        }
      }
    } catch (e) {
      print('[ODDS] fetchOdds error: $e');
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    state = const OddsState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String runnerName(int selectionId) {
    return state.runners
            .where((r) => r.selectionId == selectionId)
            .map((r) => r.name)
            .firstOrNull ??
        'Runner $selectionId';
  }
}

final oddsProvider = NotifierProvider<OddsNotifier, OddsState>(
  OddsNotifier.new,
);

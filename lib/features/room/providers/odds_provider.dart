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
  final bool isLoadingMarket;
  final bool isPolling;
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
    this.isLoadingMarket = false,
    this.isPolling = false,
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
    bool? isLoadingMarket,
    bool? isPolling,
    String? error,
    bool clearOdds = false,
    bool clearMarketId = false,
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
      isLoadingMarket: isLoadingMarket ?? this.isLoadingMarket,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasActiveOdds =>
      marketId != null && odds != null && runners.isNotEmpty;
}

class OddsNotifier extends Notifier<OddsState> {
  Timer? _pollTimer;

  @override
  OddsState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const OddsState();
  }

  Future<void> fetchCompetitions() async {
    state = state.copyWith(isLoadingCompetitions: true, clearError: true);
    try {
      final response = await _sportsDio.get('/competitions/list/4');
      final list = (response.data as List<dynamic>)
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
      isLoadingMarket: true,
      selectedEventName: eventName,
      clearError: true,
      clearOdds: true,
    );
    try {
      // Get event details -> extract MATCH_ODDS market ID + runner names
      final eventResponse = await _sportsDio.get('/events/$eventId');
      final eventData = eventResponse.data as Map<String, dynamic>;
      final catalogues = (eventData['catalogues'] as List<dynamic>?) ?? [];

      String? matchOddsMarketId;
      List<RunnerInfo> runners = [];

      for (final cat in catalogues) {
        final catMap = cat as Map<String, dynamic>;
        if (catMap['marketType'] == 'MATCH_ODDS') {
          matchOddsMarketId = catMap['marketId'] as String;
          // Runner names are already in the catalogue
          final runnersData =
              (catMap['runners'] as List<dynamic>?) ?? [];
          runners = runnersData.map((r) {
            final rm = r as Map<String, dynamic>;
            return RunnerInfo(
              selectionId: rm['id'] as int,
              name: rm['name'] as String? ?? 'Unknown',
            );
          }).toList();
          break;
        }
      }

      if (matchOddsMarketId == null) {
        state = state.copyWith(
          isLoadingMarket: false,
          error: 'No match odds market found',
        );
        return false;
      }

      state = state.copyWith(
        marketId: matchOddsMarketId,
        runners: runners,
        isLoadingMarket: false,
      );

      // Start polling odds every 3 seconds
      _startPolling(matchOddsMarketId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoadingMarket: false,
        error: 'Failed to load market data',
      );
      return false;
    }
  }

  void _startPolling(String marketId) {
    _pollTimer?.cancel();
    state = state.copyWith(isPolling: true);
    _fetchOdds(marketId);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchOdds(marketId);
    });
  }

  Future<void> _fetchOdds(String marketId) async {
    try {
      final response = await _sportsDio.get('/books/$marketId');
      final data = response.data as Map<String, dynamic>;
      final marketData = data[marketId] as Map<String, dynamic>?;
      if (marketData != null) {
        state = state.copyWith(odds: MarketOdds.fromJson(marketId, marketData));
      }
    } catch (_) {
      // Silent fail - retry in 3s
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    state = const OddsState();
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

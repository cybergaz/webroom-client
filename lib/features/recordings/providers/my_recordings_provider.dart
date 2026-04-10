import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/my_recording_model.dart';

const _pageLimit = 50;

// ─── State ────────────────────────────────────────────────────────────────────

class RecordingsState {
  final List<MyRecording> recordings;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int total;
  final DateTime? fromDate;
  final DateTime? toDate;

  const RecordingsState({
    this.recordings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.total = 0,
    this.fromDate,
    this.toDate,
  });

  bool get hasMore => recordings.length < total;

  // Use getter functions for nullable fields so callers can explicitly set null
  RecordingsState copyWith({
    List<MyRecording>? recordings,
    bool? isLoading,
    bool? isLoadingMore,
    String? Function()? error,
    int? currentPage,
    int? total,
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
  }) =>
      RecordingsState(
        recordings: recordings ?? this.recordings,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error == null ? this.error : error(),
        currentPage: currentPage ?? this.currentPage,
        total: total ?? this.total,
        fromDate: fromDate == null ? this.fromDate : fromDate(),
        toDate: toDate == null ? this.toDate : toDate(),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RecordingsNotifier extends Notifier<RecordingsState> {
  @override
  RecordingsState build() {
    Future.microtask(() => _fetch(page: 1));
    return const RecordingsState();
  }

  Future<void> applyFilter({DateTime? from, DateTime? to}) {
    return _fetch(page: 1, from: from, to: to);
  }

  Future<void> clearFilter() {
    return _fetch(page: 1);
  }

  Future<void> loadMore() {
    if (state.isLoadingMore || !state.hasMore) return Future.value();
    return _fetch(
      page: state.currentPage + 1,
      from: state.fromDate,
      to: state.toDate,
      append: true,
    );
  }

  Future<void> refresh() {
    return _fetch(page: 1, from: state.fromDate, to: state.toDate);
  }

  Future<void> _fetch({
    required int page,
    DateTime? from,
    DateTime? to,
    bool append = false,
  }) async {
    if (!append) {
      state = RecordingsState(
        isLoading: true,
        fromDate: from,
        toDate: to,
      );
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    // When appending, keep current filter from state (already set above)
    final filterFrom = append ? state.fromDate : from;
    final filterTo = append ? state.toDate : to;

    try {
      final params = <String, dynamic>{'page': page, 'limit': _pageLimit};
      if (filterFrom != null) params['from'] = filterFrom.toIso8601String();
      if (filterTo != null) {
        final endOfDay = DateTime(
            filterTo.year, filterTo.month, filterTo.day, 23, 59, 59, 999);
        params['to'] = endOfDay.toUtc().toIso8601String();
      }

      final dio = ref.read(dioClientProvider);
      final response = await dio.get(
        '/rooms/my-recordings',
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;
      final list = (data['recordings'] as List<dynamic>)
          .map((e) => MyRecording.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      state = state.copyWith(
        recordings: append ? [...state.recordings, ...list] : list,
        total: total,
        currentPage: page,
        isLoading: false,
        isLoadingMore: false,
        error: () => null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: () => 'Failed to load recordings',
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final recordingsNotifierProvider =
    NotifierProvider<RecordingsNotifier, RecordingsState>(
        RecordingsNotifier.new);

// ─── URL helper ───────────────────────────────────────────────────────────────

Future<String> fetchRecordingUrl(Dio dio, String recordingId) async {
  final response =
      await dio.get('/rooms/my-recordings/$recordingId/url');
  return response.data['url'] as String;
}

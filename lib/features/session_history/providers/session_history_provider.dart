import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/session_history_entry.dart';

class SessionHistoryNotifier
    extends AsyncNotifier<List<SessionHistoryEntry>> {
  static const _prefsKey = 'session_history_entries_v1';
  static const _uuid = Uuid();

  String? _activeEntryId;

  @override
  Future<List<SessionHistoryEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final entries = raw
        .map((s) => SessionHistoryEntry.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
    return entries;
  }

  Future<void> recordJoin({
    required String roomId,
    required String roomName,
  }) async {
    // If a previous session wasn't properly closed, close it now so the
    // new one becomes the active entry.
    if (_activeEntryId != null) {
      await recordLeave();
    }

    final entry = SessionHistoryEntry(
      id: _uuid.v4(),
      roomId: roomId,
      roomName: roomName,
      joinedAt: DateTime.now(),
    );
    _activeEntryId = entry.id;

    final current = state.value ?? const <SessionHistoryEntry>[];
    final updated = [entry, ...current];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> recordLeave() async {
    final activeId = _activeEntryId;
    if (activeId == null) return;
    _activeEntryId = null;

    final current = state.value ?? const <SessionHistoryEntry>[];
    final now = DateTime.now();
    final updated = current
        .map((e) => e.id == activeId && e.leftAt == null
            ? e.copyWith(leftAt: now)
            : e)
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> clear() async {
    _activeEntryId = null;
    state = const AsyncData([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _save(List<SessionHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

final sessionHistoryProvider =
    AsyncNotifierProvider<SessionHistoryNotifier, List<SessionHistoryEntry>>(
  SessionHistoryNotifier.new,
);

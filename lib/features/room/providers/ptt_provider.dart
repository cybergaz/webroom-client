import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/websocket_service.dart';
import 'getstream_provider.dart';

part 'ptt_provider.freezed.dart';

@freezed
abstract class PttState with _$PttState {
  const factory PttState({
    @Default(false) bool isTransmitting,
    @Default(0.0) double audioLevel,
  }) = _PttState;
}

class PttNotifier extends Notifier<PttState> {
  StreamSubscription? _audioLevelSub;

  @override
  PttState build() {
    ref.onDispose(() => _audioLevelSub?.cancel());
    return const PttState();
  }

  Future<void> startTransmitting() async {
    final call = ref.read(activeCallProvider);
    if (call == null) return;

    state = state.copyWith(isTransmitting: true);
    await call.setMicrophoneEnabled(enabled: true);
    ref.read(websocketServiceProvider).sendSpeakingEvent('speaking.start');

    _audioLevelSub?.cancel();
    _audioLevelSub = call.state.valueStream.map((s) {
      final local = s.callParticipants.where((p) => p.isLocal).firstOrNull;
      return (local?.audioLevel ?? 0).toDouble();
    }).listen((level) {
      if (state.isTransmitting) {
        state = state.copyWith(audioLevel: level);
      }
    });
  }

  Future<void> stopTransmitting() async {
    final call = ref.read(activeCallProvider);

    _audioLevelSub?.cancel();
    _audioLevelSub = null;
    state = state.copyWith(isTransmitting: false, audioLevel: 0.0);
    ref.read(websocketServiceProvider).sendSpeakingEvent('speaking.end');

    if (call == null) return;
    await call.setMicrophoneEnabled(enabled: false);
  }
}

final pttStateProvider = NotifierProvider<PttNotifier, PttState>(PttNotifier.new);

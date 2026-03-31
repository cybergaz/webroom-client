import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/websocket_service.dart';
import '../services/ptt_recording_service.dart';
import 'getstream_provider.dart';
import 'room_session_provider.dart';

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
  PttRecordingService? _recordingService;

  @override
  PttState build() {
    ref.onDispose(() {
      _audioLevelSub?.cancel();
      _recordingService?.dispose();
    });
    return const PttState();
  }

  Future<void> startTransmitting() async {
    final call = ref.read(activeCallProvider);
    if (call == null) return;

    state = state.copyWith(isTransmitting: true);
    await call.setMicrophoneEnabled(enabled: true);
    final roomId = ref.read(roomSessionProvider).value?.roomId ?? '';
    ref.read(websocketServiceProvider).sendSpeakingEvent('speaking.start', roomId);

    // Start local recording
    try {
      _recordingService ??= PttRecordingService(ref.read(dioClientProvider));
      await _recordingService!.startRecording();
    } catch (e) {
      // Recording failure is non-fatal — PTT audio still works
      print('PTT recording start failed: $e');
    }

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
    final roomSession = ref.read(roomSessionProvider).value;
    final roomId = roomSession?.roomId ?? '';
    final sessionId = roomSession?.sessionId;
    ref.read(websocketServiceProvider).sendSpeakingEvent('speaking.end', roomId);

    // Stop recording and upload (fire-and-forget)
    if (_recordingService != null && sessionId != null && roomId.isNotEmpty) {
      try {
        _recordingService!.stopAndUpload(roomId: roomId, sessionId: sessionId);
      } catch (e) {
        print('PTT recording stop failed: $e');
      }
    }

    if (call == null) return;
    await call.setMicrophoneEnabled(enabled: false);
  }
}

final pttStateProvider = NotifierProvider<PttNotifier, PttState>(PttNotifier.new);

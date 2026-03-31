import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/ptt_recording_service.dart';
import 'room_session_provider.dart';

/// Manages host mic recording: starts when host unmutes, stops + uploads when host mutes.
/// Reuses the same PttRecordingService (start/stop/upload logic is identical).
class HostRecordingNotifier extends Notifier<bool> {
  PttRecordingService? _recordingService;
  bool _isRecording = false;

  @override
  bool build() {
    ref.onDispose(() {
      _stopIfRecording();
      _recordingService?.dispose();
    });
    return false; // isRecording
  }

  /// Call when host unmutes their mic.
  Future<void> onUnmute() async {
    if (_isRecording) return;
    try {
      _recordingService ??= PttRecordingService(ref.read(dioClientProvider));
      await _recordingService!.startRecording();
      _isRecording = true;
      state = true;
    } catch (e) {
      print('Host recording start failed: $e');
    }
  }

  /// Call when host mutes their mic.
  Future<void> onMute() async {
    await _stopIfRecording();
  }

  Future<void> _stopIfRecording() async {
    if (!_isRecording || _recordingService == null) return;
    _isRecording = false;
    state = false;

    final roomSession = ref.read(roomSessionProvider).value;
    final roomId = roomSession?.roomId ?? '';
    final sessionId = roomSession?.sessionId;

    if (sessionId != null && roomId.isNotEmpty) {
      try {
        _recordingService!.stopAndUpload(roomId: roomId, sessionId: sessionId);
      } catch (e) {
        print('Host recording stop failed: $e');
      }
    }
  }
}

final hostRecordingProvider =
    NotifierProvider<HostRecordingNotifier, bool>(HostRecordingNotifier.new);

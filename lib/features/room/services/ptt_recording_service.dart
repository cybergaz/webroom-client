import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class PttRecordingService {
  final Dio _dio;
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartTime;

  PttRecordingService(this._dio);

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/ptt_$timestamp.m4a';

    _recordingStartTime = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  Future<void> stopAndUpload({
    required String roomId,
    required String sessionId,
  }) async {
    final filePath = await _recorder.stop();
    if (filePath == null || _recordingStartTime == null) return;

    final durationMs =
        DateTime.now().difference(_recordingStartTime!).inMilliseconds;
    _recordingStartTime = null;

    // Skip very short recordings (accidental taps)
    if (durationMs < 500) {
      try {
        File(filePath).deleteSync();
      } catch (_) {}
      return;
    }

    // Fire-and-forget upload
    _uploadWithRetry(filePath, roomId, sessionId, durationMs);
  }

  Future<void> _uploadWithRetry(
    String filePath,
    String roomId,
    String sessionId,
    int durationMs, {
    int attempt = 0,
  }) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          contentType: DioMediaType('audio', 'mp4'),
        ),
        'sessionId': sessionId,
        'durationMs': durationMs.toString(),
      });
      await _dio.post(
        '/rooms/$roomId/ptt-recordings',
        data: formData,
      );
      // Clean up temp file on success
      try {
        File(filePath).deleteSync();
      } catch (_) {}
    } catch (e) {
      if (attempt < 2) {
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
        return _uploadWithRetry(filePath, roomId, sessionId, durationMs,
            attempt: attempt + 1);
      }
      // All retries exhausted — discard
      print('PTT recording upload failed after 3 attempts: $e');
      try {
        File(filePath).deleteSync();
      } catch (_) {}
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}

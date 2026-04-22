// Web implementation — mutes the <audio> element that stream_video's
// `startAudio` creates for each remote audio track. Element id format comes
// from stream_video's rtc_audio_html.dart: `stream_audio_<trackIdPrefix>:audio`.
import 'package:web/web.dart' as web;

void setRemoteAudioMuted(String trackIdPrefix, bool muted) {
  final elementId = 'stream_audio_$trackIdPrefix:audio';
  final el = web.document.getElementById(elementId);
  if (el == null) return;
  if (el is web.HTMLAudioElement) {
    el.muted = muted;
    if (muted) {
      el.volume = 0;
    } else {
      el.volume = 1;
    }
  }
}

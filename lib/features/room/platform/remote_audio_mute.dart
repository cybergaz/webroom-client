// Platform-conditional mute for a specific remote participant's audio.
//
// Mobile: [MediaStreamTrack.enabled = false] reliably silences remote audio, so
// this is a no-op (the caller already calls `track.disable()`).
//
// Web: browsers keep playing remote audio via the <audio> element stream_video
// attached at call join time, even when the underlying MediaStreamTrack is
// "disabled". The web implementation mutes that element by id.
export 'remote_audio_mute_stub.dart'
    if (dart.library.js_interop) 'remote_audio_mute_web.dart';

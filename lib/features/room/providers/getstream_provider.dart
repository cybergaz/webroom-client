import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_video/stream_video.dart';
import '../../../core/constants/app_constants.dart';

/// Notifier holding the active GetStream [Call] for the current room session.
class ActiveCallNotifier extends Notifier<Call?> {
  @override
  Call? build() => null;

  void setCall(Call? call) => state = call;
}

final activeCallProvider = NotifierProvider<ActiveCallNotifier, Call?>(ActiveCallNotifier.new);

/// Initializes the [StreamVideo] singleton for a user.
Future<void> initStreamVideo({
  required String userId,
  required String userName,
  required String getstreamToken,
}) async {
  if (StreamVideo.isInitialized()) {
    return;
  }

  StreamVideo(
    AppConstants.getstreamApiKey,
    user: User.regular(userId: userId, name: userName),
    userToken: getstreamToken,
  );
}

/// Disposes the [StreamVideo] singleton (call on logout).
Future<void> disposeStreamVideo() async {
  if (StreamVideo.isInitialized()) {
    await StreamVideo.instance.disconnect();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_video/stream_video.dart';
import 'package:webroom_client/domain/enums/user_role.dart';
import '../../../core/constants/app_constants.dart';

/// Notifier holding the active GetStream [Call] for the current room session.
class ActiveCallNotifier extends Notifier<Call?> {
  @override
  Call? build() => null;

  void setCall(Call? call) => state = call;
}

final activeCallProvider = NotifierProvider<ActiveCallNotifier, Call?>(
  ActiveCallNotifier.new,
);

class GetstreamState {
  final bool isInitialized;
  final String? userToken;

  const GetstreamState({this.isInitialized = false, this.userToken});
}

class GetstreamStateNotifier extends Notifier<GetstreamState> {
  @override
  GetstreamState build() => const GetstreamState();

  /// Initializes the [StreamVideo] singleton and stores the resolved token.
  Future<void> init({
    required String userId,
    required String userName,
    required String getstreamToken,
    required UserRole role,
  }) async {
    // If we consider the singleton valid, reuse it.
    if (state.isInitialized && StreamVideo.isInitialized()) {
      return;
    }

    // A stale singleton can survive dispose() in some SDK versions.
    // Force-clean it before creating a fresh instance.
    if (StreamVideo.isInitialized()) {
      print('Stale StreamVideo singleton detected — force-disposing');
      try {
        await StreamVideo.instance.disconnect();
        await StreamVideo.instance.dispose();
      } catch (_) {}
    }

    final client = StreamVideo(
      AppConstants.getstreamApiKey,
      user: User.regular(
        userId: userId,
        name: userName,
        role: role == UserRole.host ? 'host' : 'user',
      ),
      userToken: getstreamToken,
      failIfSingletonExists: false,
    );

    final result = await client.connect();

    String resolvedToken = getstreamToken;
    if (result.isSuccess) {
      final returned = result.getDataOrNull();
      if (returned != null && returned.rawValue.isNotEmpty) {
        resolvedToken = returned.rawValue;
      }
      print('StreamVideo connected successfully');
    } else {
      print('StreamVideo connect returned failure: $result');
    }

    state = GetstreamState(isInitialized: true, userToken: resolvedToken);
  }

  /// Tears down and recreates the [StreamVideo] singleton with a fresh token.
  Future<void> reinitialize({
    required String userId,
    required String userName,
    required String getstreamToken,
    required UserRole role,
  }) async {
    await dispose();
    await init(
      userId: userId,
      userName: userName,
      getstreamToken: getstreamToken,
      role: role,
    );
  }

  /// Tears down the [StreamVideo] singleton.
  Future<void> dispose() async {
    if (StreamVideo.isInitialized()) {
      await StreamVideo.instance.disconnect();
      await StreamVideo.instance.dispose();
    }
    state = const GetstreamState();
  }
}

final getstreamStateProvider =
    NotifierProvider<GetstreamStateNotifier, GetstreamState>(
      GetstreamStateNotifier.new,
    );

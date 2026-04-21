import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_video/stream_video.dart';
import 'package:webroom_client/domain/enums/user_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

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

  const GetstreamState({this.isInitialized = false});
}

class GetstreamStateNotifier extends Notifier<GetstreamState> {
  @override
  GetstreamState build() => const GetstreamState();

  /// Initializes the [StreamVideo] singleton with a `tokenLoader` that hits
  /// our backend for a fresh GetStream token whenever the SDK needs one
  /// (first connect or on expiry). The SDK transparently refreshes — no
  /// dispose / reinitialize dance required.
  ///
  /// Awaits the coordinator WebSocket connection so downstream `getOrCreate`
  /// / `join` don't race against an in-flight auto-connect.
  Future<void> init({
    required String userId,
    required String userName,
    required String getstreamToken,
    required UserRole role,
  }) async {
    if (state.isInitialized && StreamVideo.isInitialized()) return;

    // Defensive: a stale singleton can survive dispose() in some SDK versions.
    if (StreamVideo.isInitialized()) {
      try {
        await StreamVideo.instance.disconnect();
        await StreamVideo.instance.dispose();
      } catch (_) {}
    }

    final storage = ref.read(secureStorageProvider);
    final dio = ref.read(dioClientProvider);

    final client = StreamVideo(
      AppConstants.getstreamApiKey,
      user: User.regular(
        userId: userId,
        name: userName,
        role: role == UserRole.host ? 'host' : 'user',
      ),
      userToken: getstreamToken,
      tokenLoader: (_) async {
        final response = await dio.get('/auth/getstream-token');
        return response.data['getstreamToken'] as String;
      },
      onTokenUpdated: (token) async {
        if (token.rawValue.isNotEmpty) {
          await storage.write(StorageKeys.getstreamToken, token.rawValue);
        }
      },
      failIfSingletonExists: false,
    );

    // autoConnect has already fired in the background from the constructor;
    // this await just latches onto that in-flight operation.
    final result = await client.connect();
    if (!result.isSuccess) {
      print('StreamVideo connect failed: $result');
    }

    state = const GetstreamState(isInitialized: true);
  }

  /// Tears down the [StreamVideo] singleton (e.g. on logout).
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

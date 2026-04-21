import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webroom_client/features/home/screens/home_screen.dart';
import '../../features/recordings/screens/recordings_screen.dart';
import '../../features/session_history/screens/session_history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/room/screens/user_room_screen.dart';
import '../../features/room/screens/admin_room_screen.dart';
import '../../features/room/screens/room_members_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/shell/widgets/app_shell.dart';
import '../../domain/enums/user_role.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  const publicPaths = [
    '/login',
    '/signup',
    '/splash',
  ];

  // Bridge Riverpod auth state changes → GoRouter refreshes
  final authListenable = ValueNotifier<AuthState>(ref.read(authStateProvider));
  ref.listen(authStateProvider, (_, next) {
    authListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final path = state.matchedLocation;

      return switch (authState) {
        AuthStateInitial() => null,
        AuthStateLoading() => null,
        AuthStateUnauthenticated() => () {
          if (publicPaths.any((p) => path.startsWith(p))) return null;
          return '/login';
        }(),

        AuthStateAuthenticated() => () {
          // const publicPaths = ['/login', '/signup', '/splash'];
          if (publicPaths.contains(path)) {
            return '/home';
          }
          // if (user.role == UserRole.host && path == '/home') return '/home';
          // if (user.role == UserRole.user && path.startsWith('/host'))
          // return '/home';
          return null;
          // return null;
        }(),
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/recordings',
            name: 'recordings',
            builder: (context, state) => const RecordingsScreen(),
          ),
          GoRoute(
            path: '/session-history',
            name: 'session-history',
            builder: (context, state) => const SessionHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/legal/privacy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/room/:roomId',
        name: 'room',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final authState = ref.read(authStateProvider);
          final isHost = switch (authState) {
            AuthStateAuthenticated(:final user) => user.role == UserRole.host,
            _ => false,
          };

          if (isHost) {
            return AdminRoomScreen(roomId: roomId);
          }
          return UserRoomScreen(roomId: roomId);
        },
        routes: [
          GoRoute(
            path: 'members',
            name: 'room-members',
            redirect: (context, state) {
              final authState = ref.read(authStateProvider);
              final isHost = switch (authState) {
                AuthStateAuthenticated(:final user) =>
                  user.role == UserRole.host,
                _ => false,
              };
              if (!isHost) return '/home';
              return null;
            },
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return RoomMembersScreen(roomId: roomId);
            },
          ),
        ],
      ),
    ],
  );
});

/// Tracks whether the user is currently on a room screen.
/// Room screens set this to true on init and false on dispose.
class IsOnRoomScreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isOnRoomScreenProvider = NotifierProvider<IsOnRoomScreenNotifier, bool>(
  IsOnRoomScreenNotifier.new,
);

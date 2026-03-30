import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webroom_client/features/home/screens/home_screen.dart';
import 'package:webroom_client/features/home/screens/profile_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/signup_success_screen.dart';
import '../../features/auth/screens/check_status_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/room/screens/user_room_screen.dart';
import '../../features/room/screens/admin_room_screen.dart';
import '../../features/room/screens/room_members_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../domain/enums/user_role.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  const publicPaths = [
    '/login',
    '/signup',
    '/signup/success',
    '/check-status',
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

        AuthStatePendingApproval() => () {
          const allowed = ['/signup/success', '/check-status', '/login'];
          if (allowed.contains(path)) return null;
          return '/signup/success';
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
        routes: [
          GoRoute(
            path: 'success',
            name: 'signup-success',
            builder: (context, state) {
              final requestId = state.extra as String?;
              return SignupSuccessScreen(requestId: requestId ?? '');
            },
          ),
        ],
      ),
      GoRoute(
        path: '/check-status',
        name: 'check-status',
        builder: (context, state) => const CheckStatusScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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

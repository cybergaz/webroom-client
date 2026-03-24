import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/websocket_service.dart';
import 'features/auth/providers/auth_provider.dart';

class WebroomApp extends ConsumerWidget {
  const WebroomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Connect/disconnect WS based on auth state
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      switch (next) {
        case AuthStateAuthenticated():
          ref.read(websocketServiceProvider).connect();
        case AuthStateUnauthenticated():
          ref.read(websocketServiceProvider).disconnect();
        default:
          break;
      }
    });

    return MaterialApp.router(
      title: 'Webroom',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

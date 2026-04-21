import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Give the animation a minimum display time, then start checking
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      // If auth already resolved during the delay, navigate now
      _tryNavigate(ref.read(authStateProvider));
    });
  }

  void _tryNavigate(AuthState authState) {
    if (_navigated || !mounted) return;
    switch (authState) {
      case AuthStateInitial():
      case AuthStateLoading():
        return; // still resolving — wait for listener
      case AuthStateAuthenticated():
        _navigated = true;
        context.go('/home');
      case AuthStateUnauthenticated():
        _navigated = true;
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (_, next) {
      _tryNavigate(next);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.spatial_audio_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 24),
            const Text(
              'Webroom',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 8),
            const Text(
              'Audio Rooms',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/uuid_display_card.dart';

class SignupSuccessScreen extends StatelessWidget {
  final String requestId;

  const SignupSuccessScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutCubic),
              const SizedBox(height: 24),
              const Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 12),
              const Text(
                'Share this Request ID with your admin for approval.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 32),
              if (requestId.isNotEmpty)
                UuidDisplayCard(uuid: requestId, label: 'Your Request ID')
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/check-status'),
                  child: const Text('Check Status'),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

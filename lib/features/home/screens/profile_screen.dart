import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/widgets/uuid_display_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shell/widgets/floating_pill_navbar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = switch (authState) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          FloatingPillNavBar.bottomPadding(context) + 24,
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _Avatar(name: user.name, profilePic: user.profilePic),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.role == UserRole.host
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.textHint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user.role == UserRole.host
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.textHint.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                user.role == UserRole.host ? 'Host' : 'Member',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: user.role == UserRole.host
                      ? AppColors.accent
                      : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (user.phone != null && user.phone!.isNotEmpty)
              _InfoTile(icon: Icons.phone_rounded, label: 'Phone', value: user.phone!),
            if (user.email != null && user.email!.isNotEmpty)
              _InfoTile(icon: Icons.email_rounded, label: 'Email', value: user.email!),
            if (user.role == UserRole.user && user.requestId != null) ...[
              const SizedBox(height: 24),
              UuidDisplayCard(uuid: user.requestId!, label: 'Your Request ID'),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? profilePic;

  const _Avatar({required this.name, this.profilePic});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (profilePic != null && profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(profilePic!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

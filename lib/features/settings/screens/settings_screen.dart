import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/clipboard_util.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/web_max_width.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shell/widgets/floating_pill_navbar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
      body: WebMaxWidth(
        child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            FloatingPillNavBar.bottomPadding(context) + 24,
          ),
          children: [
            const _Header(),
            const SizedBox(height: 24),
            _ProfileCard(user: user),
            if (user.role == UserRole.user &&
                (user.requestId ?? '').isNotEmpty) ...[
              const SizedBox(height: 20),
              _RequestIdCard(requestId: user.requestId!),
            ],
            const SizedBox(height: 20),
            const _LegalCard(),
            const SizedBox(height: 20),
            _AccountCard(
              onLogout: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 20),
            _AppInfoCard(role: user.role),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your account and preferences',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Reusable card shell ─────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Profile card ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.account_circle_outlined,
      title: 'Profile',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(name: user.name, profilePic: user.profilePic),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if ((user.email ?? '').isNotEmpty)
                    Text(
                      user.email!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if ((user.phone ?? '').isNotEmpty)
                    Text(
                      user.phone!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openEditNameSheet(context, user.name),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Edit Name',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openEditNameSheet(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Enter your name',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    AppSnackBar.show(
                      context,
                      message:
                          'Name change requests are coming soon. For now, ask your admin to update your profile.',
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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
        radius: 28,
        backgroundImage: NetworkImage(profilePic!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.accent,
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isHost = role == UserRole.host;
    final color = isHost ? AppColors.accent : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isHost ? 'Host' : 'Member',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request ID card ─────────────────────────────────────────────────────────

class _RequestIdCard extends StatelessWidget {
  final String requestId;

  const _RequestIdCard({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.fingerprint_rounded,
      title: 'Your Request ID',
      children: [
        const Text(
          'Share this ID with your admin to get approved or to resolve any '
          'account-related issue.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  requestId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: AppColors.accent,
                tooltip: 'Copy',
                onPressed: () async {
                  await ClipboardUtil.copy(requestId);
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      message: 'Request ID copied to clipboard',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Legal card ──────────────────────────────────────────────────────────────

class _LegalCard extends StatelessWidget {
  const _LegalCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.description_outlined,
      title: 'Legal',
      children: [
        _LinkRow(
          icon: Icons.shield_outlined,
          label: 'Privacy Policy',
          onTap: () => context.push('/legal/privacy'),
        ),
        const Divider(height: 1, color: AppColors.divider),
        _LinkRow(
          icon: Icons.article_outlined,
          label: 'Terms of Service',
          onTap: () => context.push('/legal/terms'),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── Account card ────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _AccountCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.settings_outlined,
      title: 'Account',
      children: [
        _LinkRow(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Account',
          color: AppColors.error,
          onTap: () => _confirmDelete(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () => _confirmLogout(context, onLogout),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Log Out',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently remove your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      AppSnackBar.show(
        context,
        message:
            'Account deletion is handled by your admin. Please contact them to remove your account.',
      );
    }
  }

  Future<void> _confirmLogout(
      BuildContext context, VoidCallback onLogout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You\'ll need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }
}

// ─── App information card ────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  final UserRole role;

  const _AppInfoCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.info_outline_rounded,
      title: 'App Information',
      children: [
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data == null
                ? '...'
                : '${snapshot.data!.version} (${snapshot.data!.buildNumber})';
            return _InfoRow(label: 'Version', value: version);
          },
        ),
        const SizedBox(height: 4),
        _InfoRow(
          label: 'Role',
          value: role == UserRole.host ? 'Host' : 'Member',
          valueColor: role == UserRole.host
              ? AppColors.accent
              : AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

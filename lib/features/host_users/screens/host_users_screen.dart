import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/web_max_width.dart';
import '../../shell/widgets/floating_pill_navbar.dart';
import '../models/managed_user.dart';
import '../providers/host_users_provider.dart';

class HostUsersScreen extends ConsumerStatefulWidget {
  const HostUsersScreen({super.key});

  @override
  ConsumerState<HostUsersScreen> createState() => _HostUsersScreenState();
}

class _HostUsersScreenState extends ConsumerState<HostUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(hostUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Users',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(hostUsersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: WebMaxWidth(
        maxWidth: 720,
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Manage and view all registered users.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'Search users...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: mapErrorToMessage(e),
                  onRetry: () =>
                      ref.read(hostUsersProvider.notifier).refresh(),
                ),
                data: (all) {
                  final users = _filter(all, _query);
                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(hostUsersProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        FloatingPillNavBar.bottomPadding(context) + 8,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, i) => _UserCard(
                        user: users[i],
                        index: i,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<ManagedUser> _filter(List<ManagedUser> users, String q) {
    if (q.isEmpty) return users;
    return users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          (u.requestId?.toLowerCase().contains(q) ?? false) ||
          (u.phone?.toLowerCase().contains(q) ?? false) ||
          (u.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

class _UserCard extends ConsumerWidget {
  final ManagedUser user;
  final int index;

  const _UserCard({required this.user, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: user.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.requestId ?? '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: user.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'View',
                  onTap: () => context.push('/host-users/${user.id}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => context.push('/host-users/${user.id}/edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  destructive: true,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * index),
          duration: 250.ms,
        )
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 36,
        ),
        title: Text('Delete ${user.name}?'),
        content: const Text(
          'This user will be removed from your scope and immediately lose '
          'access to every room you assigned them to. The account itself '
          'is not deleted, but you will no longer see or manage this user '
          'from here.',
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
    if (confirmed != true) return;
    try {
      await ref.read(hostUsersProvider.notifier).deleteUser(user.id);
      if (context.mounted) {
        AppSnackBar.show(context, message: '${user.name} removed');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: mapErrorToMessage(e),
          isError: true,
        );
      }
    }
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.error : AppColors.textPrimary;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: destructive
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Active', AppColors.success),
      'pending_approval' => ('Pending', AppColors.warning),
      _ => ('Inactive', AppColors.textHint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

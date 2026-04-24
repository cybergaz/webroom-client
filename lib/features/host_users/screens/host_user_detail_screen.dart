import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/clipboard_util.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/web_max_width.dart';
import '../models/managed_user.dart';
import '../providers/host_users_provider.dart';

class HostUserDetailScreen extends ConsumerWidget {
  final String userId;

  const HostUserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(hostUsersProvider);
    final user = usersAsync.value?.firstWhere(
      (u) => u.id == userId,
      orElse: () => _missing,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: WebMaxWidth(
        child: usersAsync.isLoading && user == null
            ? const Center(child: CircularProgressIndicator())
            : (user == null || user.id.isEmpty)
            ? const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : _Body(user: user),
      ),
    );
  }
}

final ManagedUser _missing = ManagedUser(
  id: '',
  requestId: null,
  name: '',
  phone: null,
  email: null,
  status: '',
  deviceName: null,
  lockedDeviceId: null,
  lockedDeviceName: null,
  allowDeviceChange: false,
  appVersion: null,
  createdAt: DateTime.now(),
  lastSeenAt: null,
);

class _Body extends ConsumerWidget {
  final ManagedUser user;

  const _Body({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _Row(label: 'Username', value: user.name),
          _Divider(),
          _Row(
            label: 'User ID',
            value: user.requestId ?? '—',
            copyable: user.requestId != null,
          ),
          _Divider(),
          _StatusRow(status: user.status),
          _Divider(),
          _Row(
            label: 'Device',
            value:
                user.lockedDeviceName ??
                user.deviceName ??
                'No device recorded',
          ),
          if (user.lockedDeviceId != null) ...[
            _Divider(),
            _Row(
              label: 'Device lock',
              value: user.allowDeviceChange
                  ? 'Change allowed'
                  : 'Locked to one device',
            ),
            const SizedBox(height: 8),
            // _DeviceAccessControls(user: user),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Edit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => context.push('/host-users/${user.id}/edit'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Force Logout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _confirmForceLogout(context, ref, user),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmForceLogout(
    BuildContext context,
    WidgetRef ref,
    ManagedUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force logout?'),
        content: Text(
          '${user.name} will be signed out of every device immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Force logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hostUsersProvider.notifier).forceLogout(user.id);
      if (context.mounted) {
        AppSnackBar.show(context, message: '${user.name} logged out');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, message: mapErrorToMessage(e), isError: true);
      }
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _Row({required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (copyable) ...[
            // const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: AppColors.accent,
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () async {
                await ClipboardUtil.copy(value);
                if (context.mounted) {
                  AppSnackBar.show(context, message: '$label copied');
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;

  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Active', AppColors.success),
      'pending_approval' => ('Pending', AppColors.warning),
      _ => ('Inactive', AppColors.textHint),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}

class _DeviceAccessControls extends ConsumerWidget {
  final ManagedUser user;

  const _DeviceAccessControls({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (!user.allowDeviceChange)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text(
                'Allow Device Change',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _run(
                context,
                () => ref
                    .read(hostUsersProvider.notifier)
                    .allowDeviceChange(user.id),
                success: '${user.name} can log in from a new device once',
              ),
            ),
          ),
        if (!user.allowDeviceChange) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text(
              'Reset Device Lock',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _run(
              context,
              () =>
                  ref.read(hostUsersProvider.notifier).resetDeviceLock(user.id),
              success: '${user.name} device lock reset',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (context.mounted) AppSnackBar.show(context, message: success);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, message: mapErrorToMessage(e), isError: true);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/web_max_width.dart';
import '../models/managed_user.dart';
import '../providers/host_users_provider.dart';

class HostUserEditScreen extends ConsumerStatefulWidget {
  final String userId;

  const HostUserEditScreen({super.key, required this.userId});

  @override
  ConsumerState<HostUserEditScreen> createState() =>
      _HostUserEditScreenState();
}

class _HostUserEditScreenState extends ConsumerState<HostUserEditScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _initialized = false;
  bool? _active;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initFromUser(ManagedUser user) {
    if (_initialized) return;
    _nameController.text = user.name;
    _active = user.isActive;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(hostUsersProvider);
    final user = usersAsync.value?.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => _missing,
    );

    if (user != null && user.id.isNotEmpty) _initFromUser(user);

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
          'Edit User',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: WebMaxWidth(
        child: user == null || user.id.isEmpty
            ? const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : SafeArea(
                child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const _Label('User ID'),
                  const SizedBox(height: 8),
                  Text(
                    user.requestId ?? '—',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _Label('Username'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 22),
                  const _Label('New Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      hint: 'Leave empty to keep current password',
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _Label('Status'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SegmentButton(
                          label: 'Active',
                          selected: _active == true,
                          onTap: () => setState(() => _active = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SegmentButton(
                          label: 'Disabled',
                          selected: _active == false,
                          onTap: () => setState(() => _active = false),
                        ),
                      ),
                    ],
                  ),
                  if (user.lockedDeviceId != null) ...[
                    const SizedBox(height: 22),
                    const _Label('Device Access'),
                    const SizedBox(height: 8),
                    _DeviceAccessActions(user: user),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              _saving ? null : () => context.pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                            foregroundColor: AppColors.textSecondary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _saving ? null : () => _save(context, user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
    );
  }

  Future<void> _save(BuildContext context, ManagedUser user) async {
    final newName = _nameController.text.trim();
    final newPassword = _passwordController.text;
    if (newName.isEmpty) {
      AppSnackBar.show(context, message: 'Username is required', isError: true);
      return;
    }
    if (newPassword.isNotEmpty && newPassword.length < 6) {
      AppSnackBar.show(
        context,
        message: 'Password must be at least 6 characters',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(hostUsersProvider.notifier);
      final nameChanged = newName != user.name;
      final passwordChanged = newPassword.isNotEmpty;

      if (nameChanged || passwordChanged) {
        await notifier.updateUser(
          user.id,
          name: nameChanged ? newName : null,
          password: passwordChanged ? newPassword : null,
        );
      }

      if (_active != null && _active != user.isActive) {
        await notifier.setStatus(user.id, active: _active!);
      }

      if (context.mounted) {
        AppSnackBar.show(context, message: 'User updated');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: mapErrorToMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceAccessActions extends ConsumerWidget {
  final ManagedUser user;

  const _DeviceAccessActions({required this.user});

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
              side: BorderSide(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
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
        AppSnackBar.show(
          context,
          message: mapErrorToMessage(e),
          isError: true,
        );
      }
    }
  }
}

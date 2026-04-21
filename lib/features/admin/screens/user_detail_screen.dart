import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../shared/widgets/app_snackbar.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $userId', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Force Logout'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Force Logout', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text(
                        'This will immediately log out the user from all devices.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Force Logout', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    try {
                      final repo = UserRepositoryImpl(UserRemoteDatasource(ref.read(dioClientProvider)));
                      await repo.forceLogout(userId);
                      if (context.mounted) {
                        AppSnackBar.show(
                          context,
                          message: 'User logged out',
                        );
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

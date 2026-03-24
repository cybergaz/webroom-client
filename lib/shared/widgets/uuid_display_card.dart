import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/clipboard_util.dart';

class UuidDisplayCard extends StatelessWidget {
  final String uuid;
  final String label;

  const UuidDisplayCard({super.key, required this.uuid, this.label = 'Your User ID'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  uuid,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.accent),
                onPressed: () async {
                  await ClipboardUtil.copy(uuid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

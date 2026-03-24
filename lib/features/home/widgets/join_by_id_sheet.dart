import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class JoinByIdSheet extends StatefulWidget {
  const JoinByIdSheet({super.key});

  @override
  State<JoinByIdSheet> createState() => _JoinByIdSheetState();
}

class _JoinByIdSheetState extends State<JoinByIdSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join Room by ID',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Room ID',
              hintText: 'Enter room UUID',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final roomId = _controller.text.trim();
                if (roomId.isNotEmpty) {
                  Navigator.pop(context);
                  context.push('/room/$roomId');
                }
              },
              child: const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../widgets/auth_button.dart';

class CheckStatusScreen extends ConsumerStatefulWidget {
  const CheckStatusScreen({super.key});

  @override
  ConsumerState<CheckStatusScreen> createState() => _CheckStatusScreenState();
}

class _CheckStatusScreenState extends ConsumerState<CheckStatusScreen> {
  final _requestIdController = TextEditingController();
  bool _isLoading = false;
  String? _status;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _requestIdController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending_approval':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved — You can now log in';
      case 'rejected':
        return 'Rejected — Contact support';
      case 'pending_approval':
        return 'Pending approval';
      case 'not_found':
        return 'Not found — Please sign up first';
      default:
        return status;
    }
  }

  Future<void> _checkStatus() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _status = null;
      _error = null;
    });
    try {
      final datasource = AuthRemoteDatasource(ref.read(dioClientProvider));
      final data = await datasource.checkStatus(_requestIdController.text.trim().toUpperCase());
      setState(() => _status = data['status'] as String?);
    } catch (e) {
      setState(() => _error = mapErrorToMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Check Account Status',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
                const Text(
                  'Enter your Request ID to check approval status',
                  style: TextStyle(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _requestIdController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Request ID',
                    hintText: 'e.g. A3K9X2M1',
                  ),
                  maxLength: 8,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Request ID is required';
                    return null;
                  },
                ).animate().fadeIn(delay: 160.ms, duration: 300.ms),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_status),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _statusColor(_status!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor(_status!).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _status == 'approved'
                                ? Icons.check_circle_rounded
                                : _status == 'rejected'
                                    ? Icons.cancel_rounded
                                    : Icons.access_time_rounded,
                            color: _statusColor(_status!),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusLabel(_status!),
                              style: TextStyle(color: _statusColor(_status!), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_status == 'approved')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Go to Login'),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                AuthButton(
                  label: 'Check Status',
                  isLoading: _isLoading,
                  onPressed: _checkStatus,
                ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

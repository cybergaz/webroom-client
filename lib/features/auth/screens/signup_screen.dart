import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/phone_input_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_mapper.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  String _phone = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phone.isNotEmpty ? _phone : null;
    final email = _emailController.text.isNotEmpty ? _emailController.text : null;

    if (phone == null && email == null) {
      setState(() => _error = 'Please provide a phone number or email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requestId = await ref
          .read(authStateProvider.notifier)
          .signup(name: _nameController.text, password: _passwordController.text, phone: phone, email: email);
      if (!mounted) return;
      context.go('/signup/success', extra: requestId);
    } catch (e) {
      setState(() => _error = mapErrorToMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
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
                  'Join Webroom',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                const Text(
                      'Request access to audio rooms',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 32),
                TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: Validators.name,
                    )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 16),
                PhoneInputField(
                      onChanged: (v) => _phone = v,
                    )
                    .animate()
                    .fadeIn(delay: 240.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 4),
                const Text(
                  'Provide at least a phone number or email',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
                const SizedBox(height: 16),
                TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    )
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 16),
                TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.password,
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms)
                    .slideY(begin: 0.1),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AuthButton(
                  label: 'Request Access',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ).animate().fadeIn(delay: 480.ms, duration: 300.ms),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/check-status'),
                    child: const Text(
                      'Already registered? Check status',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ).animate().fadeIn(delay: 560.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

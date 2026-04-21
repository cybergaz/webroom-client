import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/session_guard_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/phone_input_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/enums/user_role.dart';

enum _LoginMethod { phone, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _LoginMethod _loginMethod = _LoginMethod.phone;
  String _phone = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authStateProvider.notifier)
          .login(
            phone: _loginMethod == _LoginMethod.phone ? _phone : null,
            email: _loginMethod == _LoginMethod.email ? _email : null,
            password: _password,
          );
      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      if (authState case AuthStateAuthenticated(:final user)) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = mapErrorToMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consume and clear any session kick reason
    final kickReason = ref.read(sessionKickReasonProvider);
    if (kickReason != null) {
      // Clear it so it only shows once
      Future.microtask(() => ref.read(sessionKickReasonProvider.notifier).set(null));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kickReason != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                kickReason.message,
                                style: const TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.spatial_audio_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Webroom',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 48),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to your account',
                      style: TextStyle(color: AppColors.textSecondary),
                    ).animate().fadeIn(delay: 160.ms, duration: 300.ms),
                    const SizedBox(height: 24),
                    SegmentedButton<_LoginMethod>(
                      segments: const [
                        ButtonSegment(
                          value: _LoginMethod.phone,
                          label: Text('Phone'),
                          icon: Icon(Icons.phone_outlined),
                        ),
                        ButtonSegment(
                          value: _LoginMethod.email,
                          label: Text('Email'),
                          icon: Icon(Icons.email_outlined),
                        ),
                      ],
                      selected: {_loginMethod},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _loginMethod = selection.first;
                          _error = null;
                          _formKey.currentState?.reset();
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.accent;
                          }
                          return AppColors.surface;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.textSecondary;
                        }),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                    const SizedBox(height: 24),
                    if (_loginMethod == _LoginMethod.phone)
                      PhoneInputField(
                        onChanged: (v) => _phone = v,
                        validator: Validators.phone,
                      ).animate().fadeIn(duration: 200.ms)
                    else
                      TextFormField(
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (v) => _email = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          return Validators.email(v);
                        },
                      ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 16),
                    TextFormField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onChanged: (v) => _password = v,
                      validator: Validators.password,
                    ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
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
                      label: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _login,
                    ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 480.ms, duration: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.warmGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom back button row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero text
                              const Text(
                                'Create your\naccount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start managing projects like a pro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Form card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        AppColors.border.withValues(alpha: 0.5),
                                  ),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Column(
                                  children: [
                                    // Full Name
                                    AppTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hint: 'Alex Morgan',
                                      prefixIcon: const Icon(
                                          Icons.person_outline,
                                          size: 20),
                                      validator: (val) {
                                        if (val == null ||
                                            val.trim().isEmpty) {
                                          return 'Full name is required';
                                        }
                                        if (val.trim().length < 2) {
                                          return 'Name must be at least 2 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Email
                                    AppTextField(
                                      controller: _emailController,
                                      label: 'Work Email',
                                      hint: 'name@company.com',
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      prefixIcon: const Icon(
                                          Icons.mail_outline,
                                          size: 20),
                                      validator: (val) {
                                        if (val == null ||
                                            val.trim().isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(val.trim())) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Password
                                    AppTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'At least 8 characters',
                                      obscureText: _obscurePassword,
                                      prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (val.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    // Register Button
                                    AppButton(
                                      text: 'Create Account',
                                      isLoading: authState.isLoading,
                                      onPressed: _submit,
                                      icon: Icons.rocket_launch_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Already registered
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 4),
                                      child: const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

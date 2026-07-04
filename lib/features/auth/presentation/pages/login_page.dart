import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/helpers/validation_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../../../core/widgets/spacing.dart';
import '../../../../core/utils/context_extension.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginWithEmail(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: GlassBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.go('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: context.colorScheme.error,
                ),
              );
            }
          },
          child: Builder(
            builder: (context) {
              final authState = context.watch<AuthBloc>().state;
              final isLoading = authState is AuthLoading;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 64,
                        color: context.colorScheme.primary,
                      ),
                      Spacing.sm,
                      Text(
                        context.translate('app_title'),
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      Spacing.vertical(AppDimensions.xxl),

                      // Frosted Login Card
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sign In',
                                style: context.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Spacing.lg,
                              
                              // Email Input
                              AppTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                keyboardType: TextInputType.emailAddress,
                                validator: ValidationHelper.validateEmail,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: context.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                enabled: !isLoading,
                              ),
                              Spacing.md,

                              // Password Input
                              AppTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                obscureText: _obscurePassword,
                                validator: ValidationHelper.validatePassword,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: context.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: context.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                enabled: !isLoading,
                              ),
                              Spacing.xl,

                              // Submit button
                              AppButton(
                                text: 'Login',
                                isLoading: isLoading,
                                onPressed: () => _submit(context),
                              ),
                              Spacing.md,
                              Row(
                                children: [
                                  Expanded(child: Divider(color: context.colorScheme.onSurface.withOpacity(0.12))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                                    child: Text(
                                      'OR',
                                      style: context.textTheme.labelMedium?.copyWith(
                                        color: context.colorScheme.onSurface.withOpacity(0.4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: context.colorScheme.onSurface.withOpacity(0.12))),
                                ],
                              ),
                              Spacing.md,
                              GoogleSignInButton(
                                isLoading: isLoading,
                                onPressed: () {
                                  context.read<AuthBloc>().add(const LoginWithGoogle());
                                },
                              ),
                              Spacing.lg,

                              // Switch to Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => context.push('/register'),
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: context.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

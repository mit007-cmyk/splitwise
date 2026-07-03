import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_background.dart';
import '../../../../core/widgets/spacing.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: GlassBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              context.go('/login');
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Splitwise!',
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Spacing.vertical(AppDimensions.xxl),
                  
                  // Frosted profile glass card
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String name = 'Guest';
                      String email = 'No session';

                      if (state is Authenticated) {
                        name = state.user.name;
                        email = state.user.email;
                      }

                      return GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: AppDimensions.avatarSizeLg / 2,
                              backgroundColor: context.colorScheme.primary,
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'G',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Spacing.md,
                            Text(
                              name,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Spacing.xs,
                            Text(
                              email,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Spacing.xl,
                            
                            // Logout button
                            AppButton.secondary(
                              text: 'Log Out',
                              onPressed: () {
                                context.read<AuthBloc>().add(const LogoutRequested());
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

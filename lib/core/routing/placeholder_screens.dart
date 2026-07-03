import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/context_extension.dart';
import '../constants/app_constants.dart';
import '../widgets/app_button.dart';
import '../widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  void _navigateNext() async {
    // Wait for the initialization delay
    await Future.delayed(AppDurations.splashDelay);
    if (mounted) {
      // For now, in Phase 0, we remain on splash or we can navigate to Unknown
      // To test navigation, we redirect to unknown after splash
      context.go('/unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colorScheme.primaryContainer,
              context.colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon representing Splitwise logo in Phase 0
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.translate('app_title'),
                style: context.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.translate('splash_tagline'),
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 48),
              const AppLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 80,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  context.translate('maintenance_title'),
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.translate('maintenance_msg'),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: context.translate('common_retry'),
                  onPressed: () {
                    // Try to re-route or refresh config
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 80,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  context.translate('force_update_title'),
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.translate('force_update_msg'),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: context.translate('force_update_btn'),
                  onPressed: () {
                    // Navigate to App Store or Play Store link
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('common_error')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 80,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  '404 - Page Not Found',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.translate('unknown_error_msg'),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Go to Splash',
                  onPressed: () {
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

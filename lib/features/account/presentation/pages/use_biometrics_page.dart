import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/biometric_lock_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/security_cubit.dart';

class UseBiometricsPage extends StatelessWidget {
  const UseBiometricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final localAuth = LocalAuthentication();
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';

    return BlocProvider<SecurityCubit>(
      create: (context) => SecurityCubit(
        getIt<HiveService>(),
        getIt<AppLogger>(),
        getIt<BiometricLockService>(),
      )..loadSettings(userId),
      child: BlocConsumer<SecurityCubit, SecurityState>(
        listener: (context, state) {
          if (state.isSuccess) {
            context.pop(true);
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<SecurityCubit>();

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(false),
              ),
              elevation: 0,
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // Giant fingerprint icon
                    Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 96.sp,
                        color: const Color(0xFF1CC29F), // Teal brand tone
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Title
                    Text(
                      'Use biometrics?',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),

                    // Subtitle
                    Text(
                      'Turn on biometrics to add an extra layer of security when opening Splitwise.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    // Yes, turn on button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CC29F), // Primary teal
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state.isAuthenticating
                          ? null
                          : () => cubit.enableBiometrics(localAuth),
                      child: state.isAuthenticating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Yes, turn on biometrics',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    SizedBox(height: 12.h),

                    // No thanks button
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () => context.pop(false),
                      child: Text(
                        'No thanks',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF1CC29F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

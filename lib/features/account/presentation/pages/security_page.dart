import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/biometric_lock_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/security_cubit.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Security settings saved successfully!')),
            );
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
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Security',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Authenticate with biometrics',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Require device passcode or biometrics to open Splitwise',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSwitch(
                                value: state.isBiometricsEnabled,
                                onChanged: (val) async {
                                  if (val) {
                                    final result =
                                        await context.push('/account/security/use-biometrics');
                                    if (result == true) {
                                      cubit.loadSettings(userId);
                                    }
                                  } else {
                                    cubit.disableBiometrics();
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          const Divider(height: 1),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Timeout',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Authentication will not be required if Splitwise is reopened before the timeout expires.',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16.w),
                              DropdownButton<String>(
                                value: state.timeout,
                                dropdownColor: theme.colorScheme.surface,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: theme.colorScheme.onSurface,
                                ),
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(value: '5 seconds', child: Text('5 seconds')),
                                  DropdownMenuItem(value: '2 minutes', child: Text('2 minutes')),
                                  DropdownMenuItem(value: '5 minutes', child: Text('5 minutes')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    cubit.updateTimeout(val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        onPressed: state.isLoading ? null : cubit.saveSettings,
                        child: state.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

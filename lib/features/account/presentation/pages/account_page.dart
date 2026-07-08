import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/services/app_launcher_service.dart';
import '../../../../core/services/support_email_service.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const _platform = MethodChannel('com.example.splitwise/settings');

  Future<void> _openNotificationSettings(BuildContext context) async {
    try {
      await _platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open notifications settings: $e')),
        );
      }
    }
  }

  Future<void> _contactSupport(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final userEmail =
        authState is Authenticated ? authState.user.email : 'Unknown';
    final userId = authState is Authenticated ? authState.user.id : '';

    try {
      await getIt<SupportEmailService>().composeSupportEmail(
        userEmail: userEmail,
        userId: userId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app: $e')),
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 8.h, left: 16.w, right: 16.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
  }) {
    final scheme = context.colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.onSurfaceVariant, size: 24.sp),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          color: textColor ?? scheme.onSurface,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right, color: context.appColors.hintTextColor, size: 20.sp),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Account',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String name = 'Guest';
            String email = 'No session';

            if (state is Authenticated) {
              name = state.user.name;
              email = state.user.email;
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 36.r,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'G',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.outline, width: 1),
                                ),
                                child: Icon(Icons.camera_alt, size: 14.sp, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RouteConstants.accountSettingsPath),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu lists
                  _buildMenuItem(
                    context,
                    icon: Icons.qr_code_scanner,
                    title: 'Scan code',
                    onTap: () => context.pushNamed(RouteConstants.friendCodeName),
                  ),

                  _buildSectionHeader(context, 'Preferences'),
                  _buildMenuItem(
                    context,
                    icon: Icons.mail_outline,
                    title: 'Email settings',
                    onTap: () => context.push(RouteConstants.emailSettingsPath),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Device and push notification settings',
                    onTap: () => _openNotificationSettings(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Security',
                    onTap: () => context.push(RouteConstants.accountSecurityPath),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    onTap: () => context.push(RouteConstants.appearancePath),
                  ),

                  _buildSectionHeader(context, 'Feedback'),
                  _buildMenuItem(
                    context,
                    icon: Icons.star_outline,
                    title: 'Rate Splitwise',
                    onTap: () => AppLauncherService.rateApp(),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Contact Splitwise support',
                    onTap: () => _contactSupport(context),
                  ),

                  SizedBox(height: 16.h),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    title: 'Log out',
                    iconColor: theme.colorScheme.primary,
                    textColor: theme.colorScheme.primary,
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                  ),

                  // Footer Branding
                  SizedBox(height: 32.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        Text(
                          'Made with ✨ in Providence, RI, USA',
                          style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Copyright © 2026 Splitwise, Inc.',
                          style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'P.S. ',
                              style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              'Bunnies!',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'v26.6.3/945',
                          style: TextStyle(fontSize: 12.sp, color: context.appColors.hintTextColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

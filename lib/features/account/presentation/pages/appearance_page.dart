import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/context_extension.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Appearance',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.lg,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeOptionTile(
                      icon: Icons.light_mode_outlined,
                      title: 'Light',
                      isSelected: themeMode == ThemeMode.light,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.light),
                    ),
                    const Divider(height: 1),
                    _ThemeOptionTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark',
                      isSelected: themeMode == ThemeMode.dark,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.dark),
                    ),
                    const Divider(height: 1),
                    _ThemeOptionTile(
                      icon: Icons.contrast,
                      title: 'System default',
                      subtitle:
                          'App appearance adjusts to match your system settings',
                      isSelected: themeMode == ThemeMode.system,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24.sp, color: theme.colorScheme.onSurface),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.35,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 22.sp,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

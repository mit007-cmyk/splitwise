import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Light theme — light gray scaffold, white cards, dark text, soft shadows.
class LightTheme {
  LightTheme._();

  static ThemeData get theme {
    const colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.textPrimaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondaryLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.textPrimaryLight,
      tertiary: AppColors.infoLight,
      onTertiary: AppColors.onSecondaryLight,
      error: AppColors.errorLight,
      onError: AppColors.onErrorLight,
      errorContainer: AppColors.errorContainerLight,
      onErrorContainer: AppColors.errorLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      surfaceContainerLowest: AppColors.surfaceContainerLowestLight,
      surfaceContainerLow: AppColors.scaffoldBackgroundLight,
      surfaceContainer: AppColors.cardLight,
      surfaceContainerHigh: AppColors.surfaceContainerHighLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      shadow: AppColors.shadow,
      scrim: AppColors.shadow,
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: AppColors.onPrimaryLight,
      inversePrimary: AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackgroundLight,
      fontFamily: AppTextTheme.fontFamily,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBackgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: AppTextTheme.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.shadow.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.onPrimaryLight,
          disabledBackgroundColor: AppColors.disabledBorderLight,
          disabledForegroundColor: AppColors.textDisabledLight,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textDisabledLight,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textDisabledLight,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusLg)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.focusedBorderLight, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.disabledBorderLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        labelStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textHintLight,
        ),
        errorStyle: AppTextTheme.textTheme.bodySmall?.copyWith(
          color: AppColors.errorLight,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
        selectedLabelStyle: AppTextTheme.textTheme.labelSmall,
        unselectedLabelStyle: AppTextTheme.textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextTheme.textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primaryLight : AppColors.textSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryLight : AppColors.textSecondaryLight,
          );
        }),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bottomSheetLight,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.bottomSheetLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dialogLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onPrimaryLight,
        ),
        actionTextColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),

      extensions: const [AppThemeExtension.light],
    );
  }
}

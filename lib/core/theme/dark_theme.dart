import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Dark theme — dark gray scaffold (never pure black), readable white text,
/// soft card surfaces, proper contrast.
class DarkTheme {
  DarkTheme._();

  static ThemeData get theme {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.infoDark,
      onTertiary: AppColors.onSecondaryDark,
      error: AppColors.errorDark,
      onError: AppColors.onErrorDark,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
      surfaceContainerLow: AppColors.scaffoldBackgroundDark,
      surfaceContainer: AppColors.cardDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: AppColors.shadow,
      scrim: AppColors.shadow,
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.scaffoldBackgroundDark,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackgroundDark,
      fontFamily: AppTextTheme.fontFamily,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBackgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTextTheme.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          disabledBackgroundColor: AppColors.disabledBorderDark,
          disabledForegroundColor: AppColors.textDisabledDark,
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
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textDisabledDark,
          side: const BorderSide(color: AppColors.borderDark, width: 1.5),
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textDisabledDark,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onPrimaryDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusLg)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.focusedBorderDark, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.disabledBorderDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 2),
        ),
        labelStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textHintDark,
        ),
        errorStyle: AppTextTheme.textTheme.bodySmall?.copyWith(
          color: AppColors.errorDark,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondaryDark,
        selectedLabelStyle: AppTextTheme.textTheme.labelSmall,
        unselectedLabelStyle: AppTextTheme.textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryDark.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextTheme.textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primaryDark : AppColors.textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryDark : AppColors.textSecondaryDark,
          );
        }),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bottomSheetDark,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.bottomSheetDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dialogDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardDark,
        contentTextStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        actionTextColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDark,
        linearTrackColor: AppColors.borderDark,
        circularTrackColor: AppColors.borderDark,
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),

      extensions: const [AppThemeExtension.dark],
    );
  }
}

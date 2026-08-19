import 'package:flutter/material.dart';

/// Semantic color palette for the app. Every color has a `Light` and `Dark`
/// variant — never reference a raw [Color] value outside this file.
///
/// Usage:
/// - Structural colors (primary/secondary/error/surface/outline) are wired
///   into [ColorScheme] by `light_theme.dart` / `dark_theme.dart` and should
///   be read via `context.colorScheme` in widgets.
/// - All other semantic colors live on [AppThemeExtension] and are read via
///   `context.appColors` (see `context_extension.dart`).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------
  static const Color primaryLight = Color(0xFF15B77E);
  static const Color primaryDark = Color(0xFF26E09C);
  static const Color primaryHoverDark = Color(0xFF1AD392);

  static const Color secondaryLight = Color(0xFF2F80ED);
  static const Color secondaryDark = Color(0xFF5B9DF9);

  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF00341F);

  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF002B5C);

  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF4C0A0A);

  // ---------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------
  static const Color successLight = Color(0xFF15B77E);
  static const Color successDark = Color(0xFF26E09C);

  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  static const Color errorLight = Color(0xFFE53E3E);
  static const Color errorDark = Color(0xFFFC8181);

  static const Color infoLight = Color(0xFF2F80ED);
  static const Color infoDark = Color(0xFF5B9DF9);

  // ---------------------------------------------------------------------
  // Containers (M3 tonal surfaces)
  // ---------------------------------------------------------------------
  static const Color primaryContainerLight = Color(0xFFD1FAE5);
  static const Color primaryContainerDark = Color(0xFF064E3B);

  static const Color secondaryContainerLight = Color(0xFFDCEBFF);
  static const Color secondaryContainerDark = Color(0xFF1E3A5F);

  static const Color errorContainerLight = Color(0xFFFED7D7);
  static const Color errorContainerDark = Color(0xFF63171B);

  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF0A0A0B);

  static const Color surfaceContainerHighLight = Color(0xFFEDF0F4);
  static const Color surfaceContainerHighDark = Color(0xFF28282C);

  static const Color surfaceContainerHighestLight = Color(0xFFE7EBEF);
  static const Color surfaceContainerHighestDark = Color(0xFF2F2F34);

  // ---------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------
  static const Color scaffoldBackgroundLight = Color(0xFFF5F7FA);
  static const Color scaffoldBackgroundDark = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1E);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF212124);

  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF262629);

  static const Color bottomSheetLight = Color(0xFFFFFFFF);
  static const Color bottomSheetDark = Color(0xFF1C1C1E);

  static const Color elevatedSurfaceLight = Color(0xFF2C2C2E);
  static const Color elevatedSurfaceDark = Color(0xFF2C2C2E);
  static const Color elevatedSurfaceHoverLight = Color(0xFF3A3A3C);
  static const Color elevatedSurfaceHoverDark = Color(0xFF3A3A3C);

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textHintLight = Color(0xFFA0AEC0);
  static const Color textDisabledLight = Color(0xFFCBD5E0);

  static const Color textPrimaryDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textHintDark = Color(0xFF71717A);
  static const Color textDisabledDark = Color(0xFF52525B);

  // ---------------------------------------------------------------------
  // Financial
  // ---------------------------------------------------------------------
  static const Color incomeLight = Color(0xFF15B77E);
  static const Color incomeDark = Color(0xFF26E09C);

  static const Color expenseLight = Color(0xFFE0672B);
  static const Color expenseDark = Color(0xFFFF8A5C);

  static const Color positiveBalanceLight = Color(0xFF15B77E);
  static const Color positiveBalanceDark = Color(0xFF26E09C);

  static const Color negativeBalanceLight = Color(0xFFE0672B);
  static const Color negativeBalanceDark = Color(0xFFFF8A5C);

  static const Color settledBalanceLight = Color(0xFF718096);
  static const Color settledBalanceDark = Color(0xFF9CA3AF);

  // ---------------------------------------------------------------------
  // Borders
  // ---------------------------------------------------------------------
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2E2E32);

  static const Color dividerLight = Color(0xFFEDF2F7);
  static const Color dividerDark = Color(0xFF2A2A2E);

  static const Color focusedBorderLight = Color(0xFF15B77E);
  static const Color focusedBorderDark = Color(0xFF26E09C);

  static const Color disabledBorderLight = Color(0xFFCBD5E0);
  static const Color disabledBorderDark = Color(0xFF3A3A3E);

  // ---------------------------------------------------------------------
  // Switch
  // ---------------------------------------------------------------------
  static const Color switchOnTrackLight = Color(0xFFB8E6D5);
  static const Color switchOnThumbLight = primaryLight;
  static const Color switchOffTrackLight = Color(0xFFE9E9EA);
  static const Color switchOffThumbLight = surfaceLight;

  static const Color switchOnTrackDark = Color(0xFF2A4F47);
  static const Color switchOnThumbDark = Color(0xFF1CC29F);
  static const Color switchOffTrackDark = Color(0xFF48484A);
  static const Color switchOffThumbDark = surfaceLight;

  // ---------------------------------------------------------------------
  // Overlay / glass
  // ---------------------------------------------------------------------
  static const Color scrim = Color(0x73000000);
  static const Color shadow = Color(0xFF000000);

  static const Color glassSurfaceLight = surfaceLight;
  static const Color glassSurfaceDark = Color(0xFF1E293B);

  static const Color glassBorderLight = Color(0xFFFFFFFF);
  static const Color glassBorderDark = Color(0xFFFFFFFF);

  static const Color overlayLight = Color(0xFF000000);
  static const Color overlayDark = Color(0xFF000000);

  static const Color onImageLight = Color(0xFFFFFFFF);
  static const Color onImageDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Spending charts (theme-independent accents)
  // ---------------------------------------------------------------------
  static const Color chartTotalSpent = Color(0xFF5BB4E5);
  static const Color chartYourShare = Color(0xFF1B7CA8);

  /// Slice colours for the category pie; cycled when a group uses more
  /// categories than there are entries.
  static const List<Color> chartCategories = [
    Color(0xFF5BB4E5),
    Color(0xFF1B7CA8),
    Color(0xFF7C6CF0),
    Color(0xFF2A9D8F),
    Color(0xFFF4A261),
    Color(0xFFE76F51),
    Color(0xFFE9C46A),
    Color(0xFF9B5DE5),
  ];

  static const Color proBannerBackground = Color(0xFF6B21C8);
  static const Color proBannerButton = Color(0xFF9B5DE5);

  /// Saturated tiles for expense-category glyphs (theme-independent).
  static const Color categoryGeneral = Color(0xFF64748B);
  static const Color categoryFood = Color(0xFF0F9F6E);
  static const Color categoryGroceries = Color(0xFF16A34A);
  static const Color categoryHome = Color(0xFFB45309);
  static const Color categoryUtilities = Color(0xFFD97706);
  static const Color categoryTransportation = Color(0xFF2563EB);
  static const Color categoryEntertainment = Color(0xFF7C3AED);
  static const Color categoryHealth = Color(0xFFDC2626);
  static const Color categoryShopping = Color(0xFFDB2777);
  static const Color categoryTravel = Color(0xFF0891B2);
  static const Color categorySettlement = Color(0xFF15B77E);

  // ---------------------------------------------------------------------
  // Avatar / group placeholder backgrounds (theme-independent accents)
  // ---------------------------------------------------------------------
  static const List<Color> avatarPlaceholders = [
    Color(0xFF0F766E),
    Color(0xFF1E3A8A),
    Color(0xFF065F46),
    Color(0xFF9D174D),
    Color(0xFF374151),
  ];

  /// Four-shade palettes for the geometric identicon used when a user has no
  /// photo. Each person gets one palette, so the same name always looks the
  /// same and different people get different colours (teal, orange, …).
  static const List<List<Color>> identiconPalettes = [
    [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF5EEAD4), Color(0xFFECFDF5)],
    [Color(0xFFC2410C), Color(0xFFEA580C), Color(0xFFFDBA74), Color(0xFFFFF7ED)],
    [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF93C5FD), Color(0xFFEFF6FF)],
    [Color(0xFF6B21A8), Color(0xFFA855F7), Color(0xFFD8B4FE), Color(0xFFFAF5FF)],
    [Color(0xFF9F1239), Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFFFF1F2)],
    [Color(0xFF365314), Color(0xFF65A30D), Color(0xFFA3E635), Color(0xFFF7FEE7)],
    [Color(0xFF0E7490), Color(0xFF06B6D4), Color(0xFF67E8F9), Color(0xFFECFEFF)],
    [Color(0xFF9A3412), Color(0xFFF97316), Color(0xFFFDBA74), Color(0xFFFFF7ED)],
  ];
}

/// Theme-aware semantic colors exposed via [ThemeData.extensions].
/// Access with `context.appColors` — never pick Light/Dark variants manually.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color errorColor;

  final Color incomeColor;
  final Color expenseColor;
  final Color positiveBalanceColor;
  final Color negativeBalanceColor;
  final Color settledBalanceColor;

  final Color hintTextColor;
  final Color disabledTextColor;

  final Color focusedBorderColor;
  final Color disabledBorderColor;

  final Color switchOnTrack;
  final Color switchOnThumb;
  final Color switchOffTrack;
  final Color switchOffThumb;

  final Color elevatedSurface;
  final Color elevatedSurfaceHover;
  final Color glassSurface;
  final Color glassBorder;
  final Color overlayColor;
  final Color onImageColor;
  final Color scrimColor;

  const AppThemeExtension({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.errorColor,
    required this.incomeColor,
    required this.expenseColor,
    required this.positiveBalanceColor,
    required this.negativeBalanceColor,
    required this.settledBalanceColor,
    required this.hintTextColor,
    required this.disabledTextColor,
    required this.focusedBorderColor,
    required this.disabledBorderColor,
    required this.switchOnTrack,
    required this.switchOnThumb,
    required this.switchOffTrack,
    required this.switchOffThumb,
    required this.elevatedSurface,
    required this.elevatedSurfaceHover,
    required this.glassSurface,
    required this.glassBorder,
    required this.overlayColor,
    required this.onImageColor,
    required this.scrimColor,
  });

  static const AppThemeExtension light = AppThemeExtension(
    successColor: AppColors.successLight,
    warningColor: AppColors.warningLight,
    infoColor: AppColors.infoLight,
    errorColor: AppColors.errorLight,
    incomeColor: AppColors.incomeLight,
    expenseColor: AppColors.expenseLight,
    positiveBalanceColor: AppColors.positiveBalanceLight,
    negativeBalanceColor: AppColors.negativeBalanceLight,
    settledBalanceColor: AppColors.settledBalanceLight,
    hintTextColor: AppColors.textHintLight,
    disabledTextColor: AppColors.textDisabledLight,
    focusedBorderColor: AppColors.focusedBorderLight,
    disabledBorderColor: AppColors.disabledBorderLight,
    switchOnTrack: AppColors.switchOnTrackLight,
    switchOnThumb: AppColors.switchOnThumbLight,
    switchOffTrack: AppColors.switchOffTrackLight,
    switchOffThumb: AppColors.switchOffThumbLight,
    elevatedSurface: AppColors.elevatedSurfaceLight,
    elevatedSurfaceHover: AppColors.elevatedSurfaceHoverLight,
    glassSurface: AppColors.glassSurfaceLight,
    glassBorder: AppColors.glassBorderLight,
    overlayColor: AppColors.overlayLight,
    onImageColor: AppColors.onImageLight,
    scrimColor: AppColors.scrim,
  );

  static const AppThemeExtension dark = AppThemeExtension(
    successColor: AppColors.successDark,
    warningColor: AppColors.warningDark,
    infoColor: AppColors.infoDark,
    errorColor: AppColors.errorDark,
    incomeColor: AppColors.incomeDark,
    expenseColor: AppColors.expenseDark,
    positiveBalanceColor: AppColors.positiveBalanceDark,
    negativeBalanceColor: AppColors.negativeBalanceDark,
    settledBalanceColor: AppColors.settledBalanceDark,
    hintTextColor: AppColors.textHintDark,
    disabledTextColor: AppColors.textDisabledDark,
    focusedBorderColor: AppColors.focusedBorderDark,
    disabledBorderColor: AppColors.disabledBorderDark,
    switchOnTrack: AppColors.switchOnTrackDark,
    switchOnThumb: AppColors.switchOnThumbDark,
    switchOffTrack: AppColors.switchOffTrackDark,
    switchOffThumb: AppColors.switchOffThumbDark,
    elevatedSurface: AppColors.elevatedSurfaceDark,
    elevatedSurfaceHover: AppColors.elevatedSurfaceHoverDark,
    glassSurface: AppColors.glassSurfaceDark,
    glassBorder: AppColors.glassBorderDark,
    overlayColor: AppColors.overlayDark,
    onImageColor: AppColors.onImageDark,
    scrimColor: AppColors.scrim,
  );

  @override
  AppThemeExtension copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? errorColor,
    Color? incomeColor,
    Color? expenseColor,
    Color? positiveBalanceColor,
    Color? negativeBalanceColor,
    Color? settledBalanceColor,
    Color? hintTextColor,
    Color? disabledTextColor,
    Color? focusedBorderColor,
    Color? disabledBorderColor,
    Color? switchOnTrack,
    Color? switchOnThumb,
    Color? switchOffTrack,
    Color? switchOffThumb,
    Color? elevatedSurface,
    Color? elevatedSurfaceHover,
    Color? glassSurface,
    Color? glassBorder,
    Color? overlayColor,
    Color? onImageColor,
    Color? scrimColor,
  }) {
    return AppThemeExtension(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      errorColor: errorColor ?? this.errorColor,
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      positiveBalanceColor: positiveBalanceColor ?? this.positiveBalanceColor,
      negativeBalanceColor: negativeBalanceColor ?? this.negativeBalanceColor,
      settledBalanceColor: settledBalanceColor ?? this.settledBalanceColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      switchOnTrack: switchOnTrack ?? this.switchOnTrack,
      switchOnThumb: switchOnThumb ?? this.switchOnThumb,
      switchOffTrack: switchOffTrack ?? this.switchOffTrack,
      switchOffThumb: switchOffThumb ?? this.switchOffThumb,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      elevatedSurfaceHover: elevatedSurfaceHover ?? this.elevatedSurfaceHover,
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      overlayColor: overlayColor ?? this.overlayColor,
      onImageColor: onImageColor ?? this.onImageColor,
      scrimColor: scrimColor ?? this.scrimColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      positiveBalanceColor:
          Color.lerp(positiveBalanceColor, other.positiveBalanceColor, t)!,
      negativeBalanceColor:
          Color.lerp(negativeBalanceColor, other.negativeBalanceColor, t)!,
      settledBalanceColor:
          Color.lerp(settledBalanceColor, other.settledBalanceColor, t)!,
      hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t)!,
      disabledTextColor:
          Color.lerp(disabledTextColor, other.disabledTextColor, t)!,
      focusedBorderColor:
          Color.lerp(focusedBorderColor, other.focusedBorderColor, t)!,
      disabledBorderColor:
          Color.lerp(disabledBorderColor, other.disabledBorderColor, t)!,
      switchOnTrack: Color.lerp(switchOnTrack, other.switchOnTrack, t)!,
      switchOnThumb: Color.lerp(switchOnThumb, other.switchOnThumb, t)!,
      switchOffTrack: Color.lerp(switchOffTrack, other.switchOffTrack, t)!,
      switchOffThumb: Color.lerp(switchOffThumb, other.switchOffThumb, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      elevatedSurfaceHover:
          Color.lerp(elevatedSurfaceHover, other.elevatedSurfaceHover, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t)!,
      onImageColor: Color.lerp(onImageColor, other.onImageColor, t)!,
      scrimColor: Color.lerp(scrimColor, other.scrimColor, t)!,
    );
  }
}

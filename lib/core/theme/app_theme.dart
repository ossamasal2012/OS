import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds the app's light/dark [ThemeData]. Two color sources are
/// supported: the hand-designed "astrolabe" palette (default, always
/// available offline), or — when the user opts in from Settings — Android
/// 12+'s Material You dynamic colors extracted from the device wallpaper.
///
/// Either way, the *shape language* (rounded-but-restrained corners),
/// *type scale* (Cairo, used with real weight contrast), and *component
/// themes* below stay the same, so the app always feels like one coherent
/// product rather than a re-skin.
class AppTheme {
  AppTheme._();

  static const double _radiusSmall = 12;
  static const double _radiusMedium = 18;
  static const double _radiusLarge = 28;

  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = _tuneScheme(
      dynamicScheme ??
          ColorScheme.fromSeed(
            seedColor: AppColors.brass,
            brightness: Brightness.light,
          ),
      brightness: Brightness.light,
    );
    return _themeFrom(scheme);
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final scheme = _tuneScheme(
      dynamicScheme ??
          ColorScheme.fromSeed(
            seedColor: AppColors.brass,
            brightness: Brightness.dark,
          ),
      brightness: Brightness.dark,
    );
    return _themeFrom(scheme);
  }

  /// Overrides only the handful of tones central to the brand — primary,
  /// its foreground, the base surface, its foreground, and error — and
  /// leaves every other Material 3 tone (secondary, tertiary, the
  /// surfaceContainer ramp, outline, etc.) exactly as Flutter's algorithm
  /// derived it from the seed. This keeps every generated tone guaranteed
  /// to exist and stay contrast-safe, while still giving the app its own
  /// identity rather than a stock Material look.
  static ColorScheme _tuneScheme(
    ColorScheme base, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return base.copyWith(
      primary: AppColors.brass,
      onPrimary: isDark ? AppColors.midnight : AppColors.ink,
      surface: isDark ? AppColors.midnight : AppColors.parchment,
      onSurface: isDark ? AppColors.ivory : AppColors.ink,
      error: AppColors.signal,
      onError: Colors.white,
    );
  }

  static ThemeData _themeFrom(ColorScheme scheme) {
    final textTheme = _textTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Cairo',
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? Color.alphaBlend(AppColors.brass.withOpacity(0.06), scheme.surface)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.25 : 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSmall),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withOpacity(0.22),
        labelStyle: textTheme.labelMedium!,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withOpacity(0.20),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.4),
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary.withOpacity(0.4)
              : null,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withOpacity(0.15),
        linearTrackColor: scheme.primary.withOpacity(0.15),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusLarge)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.ivory : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : AppColors.ivory,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
      ),
    );
  }

  /// A deliberate type scale: a heavier display weight for numbers/titles
  /// that need presence (the clock, timers, headlines) and a lighter body
  /// weight for reading text — Cairo has real weight range (200–1000) so
  /// this contrast is genuine rather than faux-bold.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle style(double size, FontWeight weight, {double? height, double? letterSpacing}) {
      return TextStyle(
        fontFamily: 'Cairo',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge: style(57, FontWeight.w800, height: 1.1),
      displayMedium: style(45, FontWeight.w800, height: 1.12),
      displaySmall: style(36, FontWeight.w700, height: 1.15),
      headlineLarge: style(32, FontWeight.w700, height: 1.2),
      headlineMedium: style(28, FontWeight.w700, height: 1.22),
      headlineSmall: style(24, FontWeight.w700, height: 1.25),
      titleLarge: style(22, FontWeight.w700, height: 1.3),
      titleMedium: style(16, FontWeight.w600, height: 1.4),
      titleSmall: style(14, FontWeight.w600, height: 1.4),
      bodyLarge: style(16, FontWeight.w400, height: 1.5),
      bodyMedium: style(14, FontWeight.w400, height: 1.5),
      bodySmall: style(12, FontWeight.w400, height: 1.5, letterSpacing: 0.2),
      labelLarge: style(15, FontWeight.w700, letterSpacing: 0.1),
      labelMedium: style(13, FontWeight.w600, letterSpacing: 0.1),
      labelSmall: style(11, FontWeight.w600, letterSpacing: 0.2),
    );
  }
}

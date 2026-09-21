import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Construit les `ThemeData` clair et sombre à partir des tokens.
class ThemeService {
  const ThemeService();

  ThemeData light() => _build(Brightness.light);

  ThemeData dark() => _build(Brightness.dark);

  ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    Color c(AppColors color) => color.resolve(isDark: isDark);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c(AppColors.primary),
      onPrimary: c(AppColors.onPrimary),
      primaryContainer: c(AppColors.primaryContainer),
      onPrimaryContainer: c(AppColors.onSurface),
      secondary: c(AppColors.secondary),
      onSecondary: c(AppColors.onSecondary),
      error: c(AppColors.error),
      onError: c(AppColors.onPrimary),
      surface: c(AppColors.surface),
      onSurface: c(AppColors.onSurface),
      surfaceContainerHighest: c(AppColors.surfaceContainer),
      outline: c(AppColors.border),
    );

    final base = ThemeData(brightness: brightness).textTheme;
    final textTheme = GoogleFonts.dmSansTextTheme(base).apply(
      bodyColor: c(AppColors.onSurface),
      displayColor: c(AppColors.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c(AppColors.pageBackground),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c(AppColors.pageBackground),
        foregroundColor: c(AppColors.onSurface),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ColetteTextStyle.heading1.textStyle.copyWith(
          color: c(AppColors.onSurface),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c(AppColors.surface),
        indicatorColor: c(AppColors.primaryContainer),
        labelTextStyle: WidgetStatePropertyAll(
          ColetteTextStyle.label.textStyle.copyWith(
            color: c(AppColors.onSurface),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c(AppColors.primary)
                : c(AppColors.textSecondary),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c(AppColors.primary),
          foregroundColor: c(AppColors.onPrimary),
          minimumSize: Size.fromHeight(AppSize.xl.value),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c(AppColors.primary),
          side: BorderSide(color: c(AppColors.primary)),
          minimumSize: Size.fromHeight(AppSize.xl.value),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c(AppColors.primary),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c(AppColors.surfaceContainer),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide(color: c(AppColors.primary), width: 1.5),
        ),
        contentPadding: AppSpacing.md.all,
        labelStyle: ColetteTextStyle.label.textStyle.copyWith(
          color: c(AppColors.textSecondary),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c(AppColors.pageBackground),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl.topOnly),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c(AppColors.primary),
        foregroundColor: c(AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
      ),
      dividerTheme: DividerThemeData(color: c(AppColors.border), thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c(AppColors.onPrimary)),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c(AppColors.primary)
              : c(AppColors.border),
        ),
      ),
    );
  }
}

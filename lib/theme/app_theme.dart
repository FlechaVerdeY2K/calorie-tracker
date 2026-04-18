import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:calorie_tracker/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.lightAccent,
      onSecondary: Colors.white,
      error: Color(0xFFB91C1C),
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: Color(0xFF0F172A),
    );

    return _themeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      borderColor: AppColors.lightBorder,
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: Color(0xFF052E16),
      secondary: AppColors.darkAccent,
      onSecondary: Color(0xFF431407),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFF8FAFC),
    );

    return _themeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      borderColor: AppColors.darkBorder,
    );
  }

  static ThemeData _themeData({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color borderColor,
  }) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
    );
    final textTheme = AppTypography.buildTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle:
            textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: const CircleBorder(),
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

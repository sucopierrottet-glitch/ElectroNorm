import 'package:flutter/material.dart';

/// Normative color constants and high-contrast Material 3 theme
/// engineered for high-glare sunlight and dim mechanical rooms.
class AppColors {
  AppColors._();

  // Status threshold indicators
  static const Color compliant = Color(0xFF00E676); // Vibrant Green (<= 40%)
  static const Color caution = Color(0xFFFFD600);   // High-vis Amber (40% - 50%)
  static const Color overfilled = Color(0xFFFF1744); // High-vis Red (> 50%)

  // Conductor phase & role normative colors
  static const Color phaseA = Color(0xFF424242);        // Dark charcoal
  static const Color phaseABorder = Color(0xFFEEEEEE);  // Silver border for Phase A
  static const Color phaseB = Color(0xFFD50000);        // Deep Red
  static const Color phaseC = Color(0xFF2979FF);        // Electric Blue
  static const Color neutral = Color(0xFFECEFF1);       // Slate / White
  static const Color neutralBorder = Color(0xFF37474F); // Dark slate border for Neutral
  static const Color ground = Color(0xFF2E7D32);        // Forest Green / Copper

  // Conductor metallic cores
  static const Color coreCopper = Color(0xFFB45309);   // Copper core
  static const Color coreAluminum = Color(0xFF94A3B8); // Aluminum core

  // Mechanical room dark-first background and card surfaces
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceCard = Color(0xFF161F30);
  static const Color surfaceCardHover = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF243248);
  static const Color borderSubtle = Color(0xFF2D3C52);
  static const Color borderHighContrast = Color(0xFF4A5D7A);

  // Conduit rendering colors
  static const Color conduitWall = Color(0xFF475569);
  static const Color conduitBore = Color(0xFF070B14);
  static const Color conduitCrosshairs = Color(0xFF1E293B);

  // Text & Icons
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  /// Resolves the color of a conductor based on its designated role.
  static Color getConductorColor(String role, {int? explicitColorHex}) {
    if (explicitColorHex != null && explicitColorHex > 0) {
      return Color(explicitColorHex);
    }
    final normalized = role.toLowerCase().trim();
    if (normalized.contains('phasea') || normalized == 'l1' || normalized == 'phase a') {
      return phaseA;
    }
    if (normalized.contains('phaseb') || normalized == 'l2' || normalized == 'phase b') {
      return phaseB;
    }
    if (normalized.contains('phasec') || normalized == 'l3' || normalized == 'phase c') {
      return phaseC;
    }
    if (normalized.contains('neutral') || normalized == 'n') {
      return neutral;
    }
    if (normalized.contains('ground') || normalized == 'g' || normalized == 'egc' || normalized == 'pe') {
      return ground;
    }
    return phaseA;
  }

  /// Resolves the border color for high contrast against dark raceway bore.
  static Color? getConductorBorderColor(String role) {
    final normalized = role.toLowerCase().trim();
    if (normalized.contains('phasea') || normalized == 'l1' || normalized == 'phase a') {
      return phaseABorder;
    }
    if (normalized.contains('neutral') || normalized == 'n') {
      return neutralBorder;
    }
    return null;
  }

  /// Normative fill status color based on fill percentage and maximum allowed fill.
  static Color getFillStatusColor({
    required double fillPercentage,
    required double maxAllowedFill,
  }) {
    if (fillPercentage <= maxAllowedFill + 0.0001) {
      return compliant;
    }
    if (fillPercentage <= 50.0) {
      return caution;
    }
    return overfilled;
  }
}

/// Material 3 high-contrast theme optimized for field conditions.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseColorScheme = ColorScheme.dark(
      primary: AppColors.compliant,
      onPrimary: Colors.black,
      secondary: AppColors.phaseC,
      onSecondary: Colors.white,
      tertiary: AppColors.caution,
      onTertiary: Colors.black,
      error: AppColors.overfilled,
      onError: Colors.white,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      outline: AppColors.borderSubtle,
      outlineVariant: AppColors.borderHighContrast,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      canvasColor: AppColors.bgDark,
      dividerColor: AppColors.borderSubtle,
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.compliant,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderHighContrast, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        disabledColor: AppColors.surfaceCard.withValues(alpha: 0.4),
        selectedColor: AppColors.surfaceElevated,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.compliant, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.overfilled, width: 1.5),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// High-Contrast Dark Mode Color Palette for Field Electrician Visibility
/// Unified with FieldQuote's Obsidian Minimalist Dark Palette
class AppColors {
  // Primary Canvas & Surfaces
  static const Color bgDark = Color(0xFF0B0F19); // Deep Slate Obsidian
  static const Color surfaceCard = Color(0xFF161F30); // Elevated Slate Surface
  static const Color surfaceCardHover = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color borderSubtle = Color(0xFF243046);
  static const Color borderHighContrast = Color(0xFF334155);

  // Normative Compliance Traffic Light Indicators
  static const Color compliant = Color(0xFF00E676); // High-Viz Emerald Green (<= 40%)
  static const Color caution = Color(0xFFFFD600); // Safety Amber (40% - 50% or Jam Risk)
  static const Color overfilled = Color(0xFFFF1744); // Critical Red (> 50%)

  // Phase & Conductor Identification Colors
  static const Color phaseA = Color(0xFFEF4444); // Red Phase
  static const Color phaseABorder = Color(0xFFFCA5A5);
  static const Color phaseB = Color(0xFF3B82F6); // Blue Phase
  static const Color phaseBBorder = Color(0xFF93C5FD);
  static const Color phaseC = Color(0xFFF59E0B); // Amber/Black Phase
  static const Color phaseCBorder = Color(0xFFFCD34D);
  static const Color neutral = Color(0xFFF8FAFC); // White Neutral
  static const Color neutralBorder = Color(0xFFCBD5E1);
  static const Color ground = Color(0xFF10B981); // Green Equipment Ground
  static const Color groundBorder = Color(0xFF6EE7B7);

  // Metallic Accents (Copper vs Aluminum) & Conduit Bore Tokens
  static const Color copperTone = Color(0xFFD97706);
  static const Color aluminumTone = Color(0xFF94A3B8);
  static const Color coreCopper = Color(0xFFD97706);
  static const Color coreAluminum = Color(0xFFCBD5E1);
  static const Color conduitWall = Color(0xFF475569);
  static const Color conduitBore = Color(0xFF0F172A);
  static const Color conduitCrosshairs = Color(0xFF1E293B);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  static Color getConductorColor(String role, {int? explicitColorHex}) {
    if (explicitColorHex != null) {
      return Color(explicitColorHex);
    }
    switch (role.toLowerCase()) {
      case 'phasea':
        return phaseA;
      case 'phaseb':
        return phaseB;
      case 'phasec':
        return phaseC;
      case 'neutral':
        return neutral;
      case 'ground':
        return ground;
      default:
        return phaseA;
    }
  }

  static Color getConductorBorderColor(String role) {
    switch (role.toLowerCase()) {
      case 'phasea':
        return phaseABorder;
      case 'phaseb':
        return phaseBBorder;
      case 'phasec':
        return phaseCBorder;
      case 'neutral':
        return neutralBorder;
      case 'ground':
        return groundBorder;
      default:
        return phaseABorder;
    }
  }

  static Color getFillStatusColor({
    required double fillPercentage,
    required double maxAllowedFill,
  }) {
    if (fillPercentage <= maxAllowedFill + 0.0001) {
      return compliant;
    } else if (fillPercentage <= 50.0) {
      return caution;
    } else {
      return overfilled;
    }
  }
}

class AppTheme {
  // FieldQuote Shared Obsidian Minimalist Tokens
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color accent = Color(0xFF38BDF8);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF161F30);
  static const Color darkBorder = Color(0xFF243046);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.compliant,
        secondary: AppColors.caution,
        error: AppColors.overfilled,
        surface: AppColors.surfaceCard,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.compliant, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      ),
    );
  }
}

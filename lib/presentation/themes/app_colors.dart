import 'package:flutter/material.dart';

class AppColors {
  // Light — Brand
  static const primary = Color.fromARGB(255, 252, 120, 159);
  static const secondary = Color(0xFFFFE4EA);
  static const tertiary = Color(0xFFB8E6B8);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const secondaryForeground = Color(0xFFD6336C);
  static const background = Color(0xFFFFF9FA);

  // Light — Surfaces
  static const surface = Color(0xFFFFFFFF); // White
  static const surfaceVariant = Color(0xFFF8F9FA); // Light Gray

  // Light — Text
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF222222);
  static const textTertiary = Color(0xFF444444);
  static const textQuaternary = const Color(0xFF777777);
  static const textHint = Color(0xFFA0AEC0);

  // Status
  static const success = Color(0xFF48BB78);
  static const warning = Color(0xFFED8936);
  static const error = Color(0xFFE53E3E);
  static const info = Color(0xFF3182CE);

  // Light — Border/Shadow
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightShadow = Color.fromRGBO(0, 0, 0, 0.10);

  // Light — Gradients
  static const gradientStart = primary;
  static const gradientEnd = secondary;

  // Dark — Brand (slightly brighter to pop on dark bg)
  static const darkPrimary = Color(0xFFFF8FA3);
  static const darkSecondary = Color(0xFFFFB366);
  static const darkTertiary = Color(0xFF81C784);

  // Dark — Surfaces
  static const darkBackground = Color(0xFF0F0F0F);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceVariant = Color(0xFF2D2D30);

  // Dark — Text
  static const darkTextPrimary = Color(0xFFF7FAFC);
  static const darkTextSecondary = Color(0xFFE2E8F0);
  static const darkTextTertiary = Color(0xFFCBD5E0);
  static const darkTextHint = Color(0xFF718096);

  // Dark — Border/Shadow/Gradients
  static const darkBorder = Color(0xFF4A5568);
  static const darkShadow = Color.fromRGBO(0, 0, 0, 0.30);
  static const darkGradientStart = darkPrimary;
  static const darkGradientEnd = darkSecondary;
  static const border = Color(0xFFFFD1DC);
  // Containers (M3) — tinh chỉnh nhẹ để contrast tốt
  static const primaryContainer = Color(0xFFFFDEE5);
  static const onPrimaryContainer = Color(0xFF3D0F1A);

  static const secondaryContainer = Color(0xFFFFE7D6);
  static const onSecondaryContainer = Color(0xFF3A2012);

  static const tertiaryContainer = Color(0xFFDCF3DC);
  static const onTertiaryContainer = Color(0xFF112614);

  static const darkPrimaryContainer = Color(0xFF5E2E3A);
  static const darkOnPrimaryContainer = Color(0xFFFFE8EE);

  static const darkSecondaryContainer = Color(0xFF5F3A20);
  static const darkOnSecondaryContainer = Color(0xFFFFF0E6);

  static const darkTertiaryContainer = Color(0xFF2E4B33);
  static const darkOnTertiaryContainer = Color(0xFFEAF9EA);
}

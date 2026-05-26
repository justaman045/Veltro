import 'package:flutter/material.dart';

extension AppGradientColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get gradientPrimary =>
      _isDark ? const Color(0xFF002A5C) : const Color(0xFF007AFF);
  Color get gradientSecondary =>
      _isDark ? const Color(0xFF1D1B5C) : const Color(0xFF5E5CE6);
  Color get gradientTertiary =>
      _isDark ? const Color(0xFF4C1B3C) : const Color(0xFFAF52DE);

  LinearGradient get primaryGradient => LinearGradient(
        colors: [gradientPrimary, gradientSecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get richGradient => LinearGradient(
        colors: [gradientPrimary, gradientSecondary, gradientTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get subtleGradient => LinearGradient(
        colors: [
          gradientPrimary.withValues(alpha: 0.05),
          gradientSecondary.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

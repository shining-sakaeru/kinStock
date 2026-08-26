import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Apple Human Interface Guidelines (HIG) System Colors & Materials
class AppleColors {
  // Pure Black & Dark System Backgrounds
  static const Color systemBackground = Color(0xFF000000);
  static const Color secondarySystemBackground = Color(0xFF1C1C1E);
  static const Color tertiarySystemBackground = Color(0xFF2C2C2E);
  static const Color systemGroupedBackground = Color(0xFF000000);
  static const Color secondarySystemGroupedBackground = Color(0xFF1C1C1E);

  // Apple Material & Glass Tint
  static const Color frostedGlass = Color(0xCC1C1C1E);
  static const Color frostedGlassLight = Color(0x992C2C2E);
  static const Color separator = Color(0x33545458);
  static const Color opaqueSeparator = Color(0xFF38383A);

  // Apple System Dynamic Accents
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemIndigo = Color(0xFF5E5CE6);
  static const Color systemPurple = Color(0xFFBF5AF2);
  static const Color systemPink = Color(0xFFFF375F);
  static const Color systemTeal = Color(0xFF64D2FF);

  // Apple Typography System Labels
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99EBEBF5); // ~60%
  static const Color tertiaryLabel = Color(0x4DEBEBF5); // ~30%
  static const Color quaternaryLabel = Color(0x28EBEBF5); // ~16%

  // Category Badge Colors (Apple HIG Tint Palette)
  static Color getBadgeColor(String relationType) {
    if (relationType.contains('혈연') || relationType.contains('인척')) {
      return systemPink;
    } else if (relationType.contains('고교') || relationType.contains('대학') || relationType.contains('동문')) {
      return systemGreen;
    } else if (relationType.contains('정치') || relationType.contains('캠프')) {
      return systemIndigo;
    } else if (relationType.contains('직장') || relationType.contains('동기')) {
      return systemBlue;
    } else if (relationType.contains('지연') || relationType.contains('향우')) {
      return systemOrange;
    } else if (relationType.contains('주주') || relationType.contains('창업') || relationType.contains('대표') || relationType.contains('임원')) {
      return systemYellow;
    } else if (relationType.contains('외교') || relationType.contains('사절')) {
      return systemTeal;
    }
    return secondaryLabel;
  }
}

class AppleTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppleColors.systemBackground,
      primaryColor: AppleColors.systemBlue,
      canvasColor: AppleColors.systemBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppleColors.systemBlue,
        secondary: AppleColors.systemTeal,
        surface: AppleColors.secondarySystemBackground,
        error: AppleColors.systemRed,
        background: AppleColors.systemBackground,
      ),
      cardColor: AppleColors.secondarySystemBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppleColors.label,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppleColors.systemBlue),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppleColors.label, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.8),
        titleLarge: TextStyle(color: AppleColors.label, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
        titleMedium: TextStyle(color: AppleColors.label, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.3),
        bodyLarge: TextStyle(color: AppleColors.label, fontSize: 14, letterSpacing: -0.2),
        bodyMedium: TextStyle(color: AppleColors.secondaryLabel, fontSize: 12, letterSpacing: -0.1),
        labelSmall: TextStyle(color: AppleColors.tertiaryLabel, fontSize: 11, letterSpacing: 0),
      ),
    );
  }
}

// Backward compatibility alias
typedef AppColors = AppleColors;
typedef AppTheme = AppleTheme;

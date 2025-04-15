import 'package:flutter/material.dart';

// Tailwind color palette
class TwColors {
  // Zinc colors
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc150 = Color(0xFFF3F4F6);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Blue accent
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue400 = Color(0xFF60A5FA);

  // Success colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF7DE9BE);
  static const Color successDark = Color(0xFF047857);

  // Warning colors
  static const Color warning = Color(0xFFeab308);
  static const Color warningLight = Color(0xFFfef08a);
  static const Color warningDark = Color(0xFFa16207);
}

final ThemeData lightTheme = ThemeData(
  fontFamily: 'BricolageGrotesque',
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: TwColors.blue500,
  scaffoldBackgroundColor: TwColors.zinc50,
  dividerColor: TwColors.zinc200,
  colorScheme: ColorScheme.light(
    primary: TwColors.blue500,
    secondary: TwColors.warning,
    surface: Colors.white,
    error: Colors.red.shade400,
    onPrimary: Colors.white,
    onSecondary: TwColors.warningLight,
    onSurface: TwColors.zinc900,
    surfaceDim: TwColors.zinc150,
    tertiary: TwColors.success,
    tertiaryContainer: TwColors.successDark,
    onTertiary: TwColors.successLight,
    onError: Colors.red.shade50,
    errorContainer: Colors.red.shade800,
    secondaryContainer: TwColors.warningDark,
    primaryFixedDim: TwColors.blue400,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: TwColors.zinc900),
    displayMedium: TextStyle(color: TwColors.zinc900),
    displaySmall: TextStyle(color: TwColors.zinc900),
    bodyLarge: TextStyle(color: TwColors.zinc800),
    bodyMedium: TextStyle(color: TwColors.zinc700),
    bodySmall: TextStyle(color: TwColors.zinc600),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: TwColors.blue500,
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: TwColors.blue500,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: TwColors.blue500,
      foregroundColor: Colors.white,
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  fontFamily: 'BricolageGrotesque',
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: TwColors.blue500,
  scaffoldBackgroundColor: TwColors.zinc900,
  dividerColor: TwColors.zinc700,
  colorScheme: ColorScheme.dark(
    primary: TwColors.blue500,
    secondary: TwColors.warning,
    surface: TwColors.zinc800,
    error: Colors.red.shade300,
    onPrimary: Colors.white,
    onSecondary: TwColors.warningLight,
    onSurface: TwColors.zinc100,
    surfaceDim: TwColors.zinc700,
    tertiary: TwColors.success,
    tertiaryContainer: TwColors.successDark,
    onTertiary: TwColors.successLight,
    onError: Colors.red.shade50,
    errorContainer: Colors.red.shade700,
    secondaryContainer: TwColors.warningDark,
    primaryFixedDim: TwColors.blue400,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: TwColors.zinc100),
    displayMedium: TextStyle(color: TwColors.zinc100),
    displaySmall: TextStyle(color: TwColors.zinc100),
    bodyLarge: TextStyle(color: TwColors.zinc200),
    bodyMedium: TextStyle(color: TwColors.zinc300),
    bodySmall: TextStyle(color: TwColors.zinc400),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: TwColors.zinc800,
    foregroundColor: TwColors.zinc100,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: TwColors.blue500,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: TwColors.blue500,
      foregroundColor: Colors.white,
    ),
  ),
);

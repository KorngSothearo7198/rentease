import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4F46E5);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
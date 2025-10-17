import 'package:flutter/material.dart';

class AppColors {
  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    background: Colors.white,
  );

  static ColorScheme darkColorScheme = const ColorScheme.dark(
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
    background: Colors.black,
  );

  static ColorScheme lemonColorScheme = ColorScheme.light(
    primary: Colors.yellow.shade700,
    onPrimary: Colors.black,
    secondary: Colors.green.shade500,
    surface: Colors.yellow.shade100,
    onSurface: Colors.black,
    background: Colors.yellow.shade50,
  );

  static ColorScheme tulipColorScheme = ColorScheme.light(
    primary: Colors.red.shade700,
    onPrimary: Colors.white,
    secondary: Colors.pink.shade300,
    surface: Colors.red.shade50,
    onSurface: Colors.black,
    background: Colors.white,
  );

  static ColorScheme cakeColorScheme = ColorScheme.light(
    primary: Colors.pink.shade400,
    onPrimary: Colors.white,
    secondary: Colors.brown.shade400,
    surface: Colors.pink.shade50,
    onSurface: Colors.black,
    background: Colors.white,
  );

  static ColorScheme oceanColorScheme = ColorScheme.light(
    primary: Colors.blue.shade700,
    onPrimary: Colors.white,
    secondary: Colors.cyan.shade400,
    surface: Colors.blue.shade50,
    onSurface: Colors.black,
    background: Colors.lightBlue.shade50,
  );

  static ColorScheme forestColorScheme = ColorScheme.dark(
    primary: Colors.green.shade700,
    onPrimary: Colors.white,
    secondary: Colors.brown.shade600,
    surface: Colors.green.shade900,
    onSurface: Colors.white,
    background: Colors.green.shade900,
  );

  static Color priorityHighColor = Colors.red.shade700;
  static Color priorityMediumColor = Colors.pink.shade300;
  static Color priorityLowColor = Colors.pink.shade100;
  static Color priorityDefaultColor = Colors.grey;
}
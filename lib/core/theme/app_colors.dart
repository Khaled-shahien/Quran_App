import 'package:flutter/material.dart';

abstract class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(
    0xFFFEFBF4,
  ); // Light mode background
  static const Color lightSecondary = Color(0xFFF0E6D2); // Light mode secondary
  static const Color lightPrimary = Color(0xFF795547); // Light mode primary
  static const Color lightPageAccent = Color(
    0xFFCC9B76,
  ); // Light mode page/accent
  static const Color lightCardContent = Color(
    0xFFFFE9C2,
  ); // Light mode card content
  static const Color lightSurface = Color(0xFFFFFBF9); // Light mode surface
  static const Color lightOnSurface = Color(
    0xFF1B1B1B,
  ); // Light mode on surface text

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212); // Deep dark background
  static const Color darkSecondary = Color(0xFF1E1E1E); // Elevated dark surface
  static const Color darkPrimary = Color(
    0xFFD4B08C,
  ); // Warm gold/brown accent for dark mode
  static const Color darkPageAccent = Color(0xFF9E7C5D); // Muted gold/brown
  static const Color darkCardContent = Color(
    0xFF242424,
  ); // Dark card background
  static const Color darkSurface = Color(0xFF1A1A1A); // Dark surface

  // Captions (for both modes)
  static const Color captions = Color(0xFF675757);
  static const Color darkCaption = Color(0xFFBDBDBD);

  // Legacy Colors (for compatibility - can be removed later)
  static const Color primary = lightPrimary;
  static const Color accent = lightPageAccent;
  static const Color primaryVariant = Color(0xFF5D4037);

  // Background Colors

  // Text Colors
  static const Color primaryText = Color(0xFF1B1B1B); // Dark gray-black
  static const Color secondaryText = Color(0xFF6B6B6B); // Medium gray
  static const Color hintTextColor = Color(0xFF9E9E9E); // Light gray

  // Accent Colors
  static const Color darkCard = Color(
    0xFF2D2D2D,
  ); // Dark card color from home screen
  static const Color success = Color(0xFF81C784); // Green
  static const Color error = Color(0xFFE57373); // Red
  static const Color warning = Color(0xFFFFB74D); // Orange

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF424242);
}

import 'package:flutter/material.dart';

/// App color palette constants - Modern & Vibrant
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors - More Vibrant
  static const Color skyBlue = Color(0xFF5BA3E8); // Medium blue matching design
  static const Color skyBlueLight = Color(0xFF7BB8F0); // Lighter variant
  static const Color skyBlueDark = Color(0xFF3D8BC4); // Darker variant
  static const Color softBlue = Color(0xFFE3F2FD); // Softer, more visible
  static const Color aliceBlue = Color(0xFFF5F9FF); // Warmer background
  static const Color deepNavy = Color(0xFF1A3A5F); // Richer, more contrast
  static const Color mediumGray = Color(0xFF6B7280); // Better readability
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF3F4F6); // Subtle backgrounds

  // Vibrant Status Colors - More Visible
  static const Color errorRed = Color(0xFFEF4444); // Brighter red
  static const Color errorRedLight = Color(0xFFFEE2E2); // Light red background
  static const Color warningOrange = Color(0xFFF59E0B); // Vibrant orange
  static const Color warningOrangeLight = Color(0xFFFEF3C7); // Light orange
  static const Color successGreen = Color(0xFF10B981); // Vibrant green
  static const Color successGreenLight = Color(0xFFD1FAE5); // Light green
  static const Color lowStockYellow = Color(0xFFFCD34D); // Brighter yellow
  static const Color infoBlue = Color(0xFF3B82F6); // Info blue
  static const Color infoBlueLight = Color(0xFFDBEAFE); // Light info blue

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5BA3E8), Color(0xFF3D8BC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static BoxShadow get cardShadow => BoxShadow(
    color: skyBlue.withOpacity(0.15),
    blurRadius: 12,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );

  static BoxShadow get buttonShadow => BoxShadow(
    color: skyBlue.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );
}


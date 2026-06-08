import 'package:flutter/material.dart';

class SafeTalkTheme {
  // Psychological Therapeutic Brand Color Palette
  static const Color bgMidnight = Color(0xFFFAF9FC);      // Luminous Lavender Off-White
  static const Color bgForest = Color(0xFFEFF0F7);        // Soft Periwinkle Cream
  static const Color brandSage = Color(0xFF537A70);       // Soothing Muted Sage Green (Listener theme)
  static const Color brandSageLight = Color(0xFF6B8E86);
  static const Color brandTherapist = Color(0xFF6B4F82);  // Prestige Royal Amethyst Purple (Therapist theme)
  static const Color brandTherapistLight = Color(0xFF836999);
  static const Color brandTerracotta = Color(0xFF6C82C5);  // Calming Periwinkle Blue (Seeker theme)
  static const Color brandGold = Color(0xFFE09384);        // Reassuring Warm Peach Coral

  static Color getListenerColor(bool isTherapist) => isTherapist ? brandTherapist : brandSage;
  static Color getListenerColorLight(bool isTherapist) => isTherapist ? brandTherapistLight : brandSageLight;
  
  static const Color cardBg = Color(0xFFFFFFFF);          // Soft Pure White Cards
  static const Color borderSage = Color(0xFFE4E8F2);      // Very light periwinkle borders
  
  static const Color textPrimary = Color(0xFF222C3D);     // Deep Slate Indigo for legibility
  static const Color textSecondary = Color(0xFF5B6980);   // Muted Lavender-Slate
  static const Color textMuted = Color(0xFF909DB0);

  // Organic Custom Geometry
  static const BorderRadius organicCardRadius = BorderRadius.only(
    topLeft: Radius.circular(24),
    bottomRight: Radius.circular(24),
    topRight: Radius.circular(8),
    bottomLeft: Radius.circular(8),
  );

  static const BorderRadius standardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(50));

  // Ambient Drop Shadow Design for Therapeutic Palette
  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.05}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 18,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ];
  }

  // Premium Background Gradients
  static const BoxDecoration ambientBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [bgMidnight, bgForest],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const BoxDecoration glassCardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: organicCardRadius,
    border: Border.fromBorderSide(
      BorderSide(color: borderSage, width: 1.5),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x0C6C82C5), // Extremely soft Periwinkle drop shadow
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Unified Text Styles
  static TextStyle displayStyle({required Color color}) => TextStyle(
        fontFamily: 'Georgia',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headingStyle({required Color color}) => TextStyle(
        fontFamily: 'Georgia',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bodyStyle({required Color color, bool bold = false}) => TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 15,
        height: 1.4,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: color,
      );

  static TextStyle captionStyle({required Color color}) => TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 12,
        letterSpacing: 0.1,
        color: color,
      );
}

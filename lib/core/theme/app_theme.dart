import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
/// Premium, traditional palette: temple saffron, deep maroon, gold, cream.
class AppTheme {
  AppTheme._();
 
  static const saffron = Color(0xFFE07A1F);
  static const maroon = Color(0xFF6B1414);
  static const gold = Color(0xFFC9A227);
  static const cream = Color(0xFFFBF4E6);
  static const surface = Color(0xFFFFFBF2);
  static const ink = Color(0xFF2A1A12);
  static const error = Color(0xFFB00020);
 
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final text = GoogleFonts.tiroDevanagariSanskritTextTheme(base.textTheme)
        .apply(bodyColor: ink, displayColor: maroon);
 
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: saffron,
        secondary: gold,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: ink,
        error: error,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: maroon,
        foregroundColor: cream,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.tiroDevanagariSanskrit(
          color: gold,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1.5,
        shadowColor: gold.withValues(alpha: .25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withValues(alpha: .35)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: .4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withValues(alpha: .4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: saffron, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.barlowCondensed(
        fontSize: 28,
        fontWeight: FontWeight.w900,
      ),
      headlineMedium: GoogleFonts.barlow(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.barlow(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.barlow(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: GoogleFonts.barlow(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.1,
      ),
    );
  }
}

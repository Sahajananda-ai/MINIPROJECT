import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Canonical SaveBite design tokens.
///
/// Until now the palette was re-declared per screen, and two different
/// "charcoal" hexes had already drifted apart. Every file should read colors
/// and type styles from here so the app stays one coherent visual language
/// (Too Good To Go warm cream + teal, with Indian delivery-app data density).
abstract final class SaveBiteTheme {
  // ─── Warm matte surfaces ───
  static const Color cream = Color(0xFFF5F0E8);
  static const Color creamWarm = Color(0xFFEDE6DA);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color white = Colors.white;

  // ─── Lines & text ───
  static const Color border = Color(0xFFD4C9B8);
  static const Color borderInput = Color(0xFFC2B5A0);
  static const Color charcoal = Color(0xFF2B1D15);
  static const Color charcoalSoft = Color(0xFF2D2D2D);
  static const Color textMuted = Color(0xFF6B5D52);

  // ─── Brand ───
  static const Color tealPrimary = Color(0xFF006C5B);
  static const Color tealDark = Color(0xFF005A4B);
  static const Color tealDeep = Color(0xFF004D40);
  static const Color tealWash = Color(0xFFE0F2F1);
  static const Color tealSubtle = Color(0xFFE6F2EF);

  // ─── Rescue accents ───
  static const Color warmAmber = Color(0xFFFF8C42);
  static const Color warmAmberHover = Color(0xFFE87A35);

  // ─── Feedback ───
  static const Color danger = Color(0xFFD94040);
  static const Color success = Color(0xFF2E7D32);
  static const Color successSubtle = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF9A825);

  // ─── Radii ───
  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 24;
  static const double radiusXL = 32;

  // ─── Type (Playfair Display display headings + Inter for everything else) ──
  static TextStyle display({double size = 30, Color? color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? charcoal,
        height: 1.15,
      );

  static TextStyle title({double size = 18, Color? color, FontWeight w = FontWeight.w800}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        color: color ?? charcoal,
        height: 1.2,
      );

  static TextStyle eyebrow({Color? color, double size = 11}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: color ?? tealPrimary,
      );

  static TextStyle body({double size = 14, Color? color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        color: color ?? textMuted,
        height: 1.45,
      );

  static TextStyle code({double size = 22, Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: color ?? tealPrimary,
      );

  /// Soft universal shadow used by cards across the app.
  static List<BoxShadow> cardShadow({double alpha = 0.05, double blur = 16}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: alpha),
          blurRadius: blur,
          offset: const Offset(0, 5),
        ),
      ];
}

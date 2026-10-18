import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding.dart';
import 'widgets/mobile_frame_wrapper.dart';

void main() {
  runApp(const MysteryBoxApp());
}

class MysteryBoxApp extends StatelessWidget {
  const MysteryBoxApp({super.key});

  // SaveBite matte palette
  static const Color _tealPrimary = Color(0xFF006C5B);
  static const Color _cream = Color(0xFFF5F0E8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveBite - Mystery Box Rescue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _tealPrimary,
          primary: _tealPrimary,
          surface: _cream,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _cream,
        appBarTheme: AppBarTheme(
          backgroundColor: _tealPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _tealPrimary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      builder: (context, child) {
        return MobileFrameWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const OnboardingScreen(),
    );
  }
}

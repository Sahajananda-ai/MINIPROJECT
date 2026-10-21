import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding.dart';
import 'screens/student_shell.dart';
import 'screens/vendor_dashboard.dart';
import 'services/session_service.dart';
import 'widgets/mobile_frame_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Restore any previous session before the first frame, so a returning user
  // lands straight in their own experience instead of the onboarding carousel.
  await SessionService().load();
  runApp(const SaveBiteApp());
}

/// Decides where the app starts: a signed-in student goes to their shell, a
/// signed-in vendor to their portal, and everyone else to onboarding.
class EntryRouter extends StatelessWidget {
  const EntryRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService();
    if (!session.isLoaded) return const _BrandSplash();
    if (session.isVendor) return const VendorDashboardScreen();
    if (session.isStudent) return const StudentShell();
    return const OnboardingScreen();
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaveBiteApp.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SaveBiteApp.tealPrimary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'SaveBite',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: SaveBiteApp.charcoal,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: SaveBiteApp.tealPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class SaveBiteApp extends StatelessWidget {
  const SaveBiteApp({super.key});

  // ─── SaveBite Design Tokens (from replica/design/tokens.json) ───
  // Warm matte palette inspired by Pizza Amici + papermorphism
  static const Color cream       = Color(0xFFF5F0E8);
  static const Color creamWarm   = Color(0xFFEDE6DA);
  static const Color surface     = Color(0xFFFFFDF9);
  static const Color border      = Color(0xFFD4C9B8);
  static const Color borderInput = Color(0xFFC2B5A0);
  static const Color charcoal    = Color(0xFF2B1D15);
  static const Color textMuted   = Color(0xFF6B5D52);

  static const Color tealPrimary = Color(0xFF006C5B);
  static const Color tealDark    = Color(0xFF005A4B);
  static const Color tealSubtle  = Color(0xFFE6F2EF);

  static const Color warmAmber      = Color(0xFFFF8C42);
  static const Color warmAmberHover = Color(0xFFE87A35);

  static const Color danger        = Color(0xFFD94040);
  static const Color success       = Color(0xFF2E7D32);
  static const Color successSubtle = Color(0xFFE8F5E9);
  static const Color warning       = Color(0xFFF9A825);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveBite — Rescue Surplus Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: charcoal,
          displayColor: charcoal,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: tealPrimary,
          primary: tealPrimary,
          secondary: warmAmber,
          surface: cream,
          error: danger,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: cream,

        // App Bar — warm teal header
        appBarTheme: AppBarTheme(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),

        // Elevated Button — rounded pill with bounce shadow
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tealPrimary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: tealPrimary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: tealPrimary,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),

        // Card — warm papermorphism surface
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // Input — warm rounded inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderInput),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: tealPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: danger),
          ),
          labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
          hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
        ),

        // Bottom Navigation — cream surface
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: tealPrimary,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: charcoal,
          contentTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
        ),

        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: CircleBorder(),
        ),

        // Divider
        dividerTheme: DividerThemeData(
          color: border.withValues(alpha: 0.4),
          thickness: 1,
        ),
      ),
      builder: (context, child) {
        return MobileFrameWrapper(child: child ?? const SizedBox.shrink());
      },
      initialRoute: '/',
      routes: {
        // Named route so "Sign out" (and any future deep link) can restart at
        // the real entry decision instead of onboarding.
        '/': (context) => const EntryRouter(),
      },
    );
  }
}

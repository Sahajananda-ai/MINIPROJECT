import 'package:flutter/material.dart';
import 'screens/onboarding.dart';
import 'screens/vendor_dashboard.dart';

void main() {
  runApp(const MysteryBoxApp());
}

class MysteryBoxApp extends StatelessWidget {
  const MysteryBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mystery Box',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming Inter or system font for a clean modern look
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C5B), // Too Good To Go style deep rich green/teal
          primary: const Color(0xFF006C5B),
          brightness: Brightness.light,
        ),
      ),
      home: const VendorDashboardScreen(),
    );
  }
}

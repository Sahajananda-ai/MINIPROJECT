import 'package:flutter/material.dart';
import 'screens/onboarding.dart';
import 'widgets/mobile_frame_wrapper.dart';

void main() {
  runApp(const MysteryBoxApp());
}

class MysteryBoxApp extends StatelessWidget {
  const MysteryBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveBite - Mystery Box Rescue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C5B), // Too Good To Go style deep rich green/teal
          primary: const Color(0xFF006C5B),
          brightness: Brightness.light,
        ),
      ),
      builder: (context, child) {
        return MobileFrameWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const OnboardingScreen(),
    );
  }
}

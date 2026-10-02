import 'package:flutter/material.dart';
import 'screens/student_map.dart';
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
      // Here is where we inject the premium Google Material Design feel!
      theme: ThemeData(
        useMaterial3: true, // Uses the latest Material Design 3 guidelines
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange, // A nice food-app style color
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const VendorDashboardScreen(),
    );
  }
}

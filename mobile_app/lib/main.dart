import 'package:flutter/material.dart';
import 'screens/student_home.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
      ),
      home: const StudentHomeScreen(),
    );
  }
}

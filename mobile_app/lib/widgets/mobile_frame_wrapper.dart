import 'dart:math';
import 'package:flutter/material.dart';

/// Wraps the application in a sleek, realistic smartphone chassis
/// when viewed on desktop browsers or wide displays (> 520px).
/// On native mobile devices or narrow screens, it renders edge-to-edge.
class MobileFrameWrapper extends StatefulWidget {
  final Widget child;

  const MobileFrameWrapper({super.key, required this.child});

  @override
  State<MobileFrameWrapper> createState() => _MobileFrameWrapperState();
}

class _MobileFrameWrapperState extends State<MobileFrameWrapper> {
  bool _enableFrame = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the window is already mobile-sized (< 520px) or user turned frame off,
        // render the app natively edge-to-edge.
        if (constraints.maxWidth <= 520 || !_enableFrame) {
          return widget.child;
        }

        // Standard modern smartphone dimensions (iPhone 15 Pro / Pixel 8 scale)
        const double phoneWidth = 412.0;
        final double maxAvailableHeight = constraints.maxHeight - 48.0;
        final double phoneHeight = min(880.0, max(600.0, maxAvailableHeight));

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark slate presentation canvas
          body: Stack(
            children: [
              // 1. Ambient Background Glow & Tech Pattern
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0A0F1D),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Subtle Watermark Branding in Background
              Positioned(
                top: 24,
                left: 32,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006C5B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lunch_dining_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SaveBite • Mystery Box Rescue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Live Prototype Preview • BMSIT&M Review 1",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Frame Toggle Button (Top Right)
              Positioned(
                top: 24,
                right: 32,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _enableFrame = !_enableFrame;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _enableFrame ? Icons.fullscreen_rounded : Icons.phone_iphone_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _enableFrame ? "Full Window" : "Phone Frame",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Centered Realistic Smartphone Frame
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hardware Buttons (Left side: Volume rocker)
                      Positioned(
                        left: -3,
                        top: 140,
                        child: Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -3,
                        top: 205,
                        child: Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Hardware Button (Right side: Power button)
                      Positioned(
                        right: -3,
                        top: 165,
                        child: Container(
                          width: 4,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Outer Phone Chassis
                      Container(
                        width: phoneWidth + 24, // 12px bezel on each side
                        height: phoneHeight + 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E242B), // Matte titanium bezel
                          borderRadius: BorderRadius.circular(52),
                          border: Border.all(
                            color: const Color(0xFF3B4856), // Subtle metallic edge highlight
                            width: 2.0,
                          ),
                          boxShadow: [
                            // Deep ambient chassis shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 50,
                              spreadRadius: 8,
                              offset: const Offset(0, 25),
                            ),
                            // Brand teal accent reflection
                            BoxShadow(
                              color: const Color(0xFF006C5B).withValues(alpha: 0.2),
                              blurRadius: 70,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          // Phone Screen Viewport
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(42),
                            child: SizedBox(
                              width: phoneWidth,
                              height: phoneHeight,
                              child: Stack(
                                children: [
                                  // The actual Flutter App (Override MediaQuery so the app knows its mobile size)
                                  Positioned.fill(
                                    child: MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        size: Size(phoneWidth, phoneHeight),
                                        padding: const EdgeInsets.only(top: 36, bottom: 20),
                                        viewPadding: const EdgeInsets.only(top: 36, bottom: 20),
                                      ),
                                      child: widget.child,
                                    ),
                                  ),

                                  // Top Camera Dynamic Island / Notch
                                  Positioned(
                                    top: 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: 110,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Tiny camera lens reflection
                                            Container(
                                              margin: const EdgeInsets.only(right: 14),
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D1B2A),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFF1E3A5F),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Home Indicator Bar
                                  Positioned(
                                    bottom: 6,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 125,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

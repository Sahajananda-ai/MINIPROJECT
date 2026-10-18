import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _heroController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late AnimationController _pulseController;

  // SaveBite warm matte color palette
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _tealDark = Color(0xFF004D40);
  static const Color _tealPrimary = Color(0xFF006C5B);
  static const Color _warmAmber = Color(0xFFFF8C42);
  static const Color _charcoal = Color(0xFF2D2D2D);

  final List<Map<String, String>> _pages = const [
    {
      'image': 'assets/images/hero_food_rescue.jpg',
      'tagline': 'FIGHT FOOD WASTE',
      'title': 'Rescue delicious\nsurplus food',
      'body':
          'Get mystery boxes packed with quality surplus from your favourite local bakeries, cafés & restaurants — at half the price or less.',
    },
    {
      'image': 'assets/images/onboard_save_planet.jpg',
      'tagline': 'SAVE MONEY & THE PLANET',
      'title': 'Good for you.\nGreat for Earth.',
      'body':
          'Every box you rescue prevents food from going to landfill, cutting CO₂ emissions. Eat well, pay less, save the planet.',
    },
    {
      'image': 'assets/images/onboard_mystery_box.jpg',
      'tagline': 'SURPRISE & DELIGHT',
      'title': 'Open, enjoy,\nrepeat ✨',
      'body':
          "You won't know exactly what's inside until you pick it up. That's the fun — a delicious daily surprise waiting for you!",
    },
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _heroController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToRoleSelection() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const RoleSelectionScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Background Pattern — subtle organic shapes
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tealPrimary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _warmAmber.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _heroController.reset();
              _heroController.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (context, i) => _buildPage(_pages[i]),
          ),

          // Skip button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: _goToRoleSelection,
              style: TextButton.styleFrom(
                foregroundColor: _tealDark.withValues(alpha: 0.6),
              ),
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom — Dots + CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated Dot Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == i ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? _tealPrimary : _tealPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // CTA Button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: _currentPage == _pages.length - 1
                        ? ElevatedButton(
                            key: const ValueKey('start'),
                            onPressed: _goToRoleSelection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tealPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 8,
                              shadowColor: _tealPrimary.withValues(alpha: 0.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.05);
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: FloatingActionButton(
                              key: const ValueKey('next'),
                              backgroundColor: _tealPrimary,
                              elevation: 6,
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
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
  }

  Widget _buildPage(Map<String, String> data) {
    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroFade,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
          child: Column(
            children: [
              // Hero Image — full-width rounded with overlay gradient
              Expanded(
                flex: 55,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _charcoal.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            data['image']!,
                            fit: BoxFit.cover,
                          ),
                          // Bottom gradient for text readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Floating badge
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _warmAmber,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _warmAmber.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'UP TO 70% OFF',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Text Content
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _tealPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['tagline']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _tealPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title — bold serif-like heading
                      Text(
                        data['title']!,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _charcoal,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Body
                      Flexible(
                        child: Text(
                          data['body']!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _charcoal.withValues(alpha: 0.6),
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

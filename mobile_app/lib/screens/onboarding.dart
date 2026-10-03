import 'package:flutter/material.dart';
import 'student_home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Premium Onboarding Data
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Rescue Delicious Food",
      "description": "Get high-quality surplus food from your favorite local bakeries and restaurants at a fraction of the price.",
      "image": "https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop",
    },
    {
      "title": "Save Money & The Planet",
      "description": "Every Mystery Box you buy helps reduce food waste and greenhouse gas emissions. Eat good, feel good.",
      "image": "https://images.unsplash.com/photo-1495147466023-e6a92579b5ea?q=80&w=800&auto=format&fit=crop",
    },
    {
      "title": "Surprise & Delight",
      "description": "You won't know exactly what's inside until you pick it up. It's a delicious daily surprise waiting for you!",
      "image": "https://images.unsplash.com/photo-1555507036-ab1f40ce88f4?q=80&w=800&auto=format&fit=crop",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Swipeable Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => _buildPage(
              image: _onboardingData[index]["image"]!,
              title: _onboardingData[index]["title"]!,
              description: _onboardingData[index]["description"]!,
            ),
          ),
          
          // Bottom Navigation & Indicators
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Animated Dot Indicators
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 8),
                      height: 10,
                      width: _currentPage == index ? 30 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                // Next / Get Started Button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentPage == _onboardingData.length - 1
                      ? ElevatedButton(
                          key: const ValueKey('start'),
                          onPressed: () {
                            // Smoothly transition to the Home Screen
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const StudentHomeScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 500),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      : FloatingActionButton(
                          key: const ValueKey('next'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 5,
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper to build each swipeable screen
  Widget _buildPage({required String image, required String title, required String description}) {
    return Column(
      children: [
        // Huge, edge-to-edge premium imagery
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Text Content Section
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

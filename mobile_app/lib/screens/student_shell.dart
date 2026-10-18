import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_home.dart';
import 'student_map.dart';
import 'student_orders.dart';
import 'student_profile.dart';
import '../services/order_manager.dart';

/// The main shell for the Student experience.
/// Supports programmatic tab switching and displays active rescue tracking.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  /// Static tab notifier to allow any child screen or checkout to switch tabs
  static final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);

  static void switchTab(int index) {
    currentTabNotifier.value = index;
  }

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  final OrderManager _orderManager = OrderManager();

  // SaveBite matte palette
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _tealPrimary = Color(0xFF006C5B);
  static const Color _warmAmber = Color(0xFFFF8C42);
  static const Color _charcoal = Color(0xFF2D2D2D);

  final List<Widget> _screens = const [
    StudentHomeScreen(),
    StudentMapScreen(),
    StudentOrdersScreen(),
    StudentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    StudentShell.currentTabNotifier.addListener(_onTabNotifierChanged);
    _orderManager.addListener(_onOrderStateChanged);
  }

  @override
  void dispose() {
    StudentShell.currentTabNotifier.removeListener(_onTabNotifierChanged);
    _orderManager.removeListener(_onOrderStateChanged);
    super.dispose();
  }

  void _onTabNotifierChanged() {
    if (mounted) setState(() {});
  }

  void _onOrderStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = StudentShell.currentTabNotifier.value;
    final activeOrders = _orderManager.activeOrders;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),

          // Active Pickup Sticky Prompt
          if (activeOrders.isNotEmpty && (currentIndex == 0 || currentIndex == 3))
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 16,
              right: 16,
              child: Hero(
                tag: 'active_rescue_banner',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => StudentShell.switchTab(1),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006C5B), Color(0xFF004D40)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _tealPrimary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _warmAmber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "1 Mystery Box Ready for Pickup!",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${activeOrders.first.vendorName} • Tap to view route & pass",
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _charcoal.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => StudentShell.switchTab(index),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: _tealPrimary,
            unselectedItemColor: _charcoal.withValues(alpha: 0.35),
            selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  backgroundColor: _warmAmber,
                  smallSize: 8,
                  child: const Icon(Icons.map_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  backgroundColor: _warmAmber,
                  smallSize: 8,
                  child: const Icon(Icons.map_rounded),
                ),
                label: 'Radar Map',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  label: Text(
                    '${activeOrders.length}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _tealPrimary,
                  child: const Icon(Icons.confirmation_number_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  label: Text(
                    '${activeOrders.length}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _tealPrimary,
                  child: const Icon(Icons.confirmation_number_rounded),
                ),
                label: 'My Pickups',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.eco_outlined),
                activeIcon: Icon(Icons.eco_rounded),
                label: 'Impact',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),

          // Active Pickup Sticky Prompt (Shows if an active box is pending and user is on Home/Impact)
          if (activeOrders.isNotEmpty && (currentIndex == 0 || currentIndex == 3))
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Hero(
                tag: 'active_rescue_banner',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      StudentShell.switchTab(1); // Jump to Radar Map
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006C5B), Color(0xFF004D40)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF006C5B).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_walk_rounded, color: Colors.black87, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "1 Mystery Box Ready for Pickup!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${activeOrders.first.vendorName} • Tap to view route & pass",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
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
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              StudentShell.switchTab(index);
            },
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF006C5B),
            unselectedItemColor: Colors.grey[400],
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore_rounded),
                activeIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  backgroundColor: Colors.amber,
                  smallSize: 8,
                  child: const Icon(Icons.map_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  backgroundColor: Colors.amber,
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
                  backgroundColor: const Color(0xFF006C5B),
                  child: const Icon(Icons.confirmation_number_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: activeOrders.isNotEmpty,
                  label: Text(
                    '${activeOrders.length}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF006C5B),
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

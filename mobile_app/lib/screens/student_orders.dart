import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_manager.dart';
import '../services/api_service.dart';
import 'student_shell.dart';

class StudentOrdersScreen extends StatefulWidget {
  const StudentOrdersScreen({super.key});

  @override
  State<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends State<StudentOrdersScreen> {
  final OrderManager _orderManager = OrderManager();

  // SaveBite matte palette
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _tealPrimary = Color(0xFF006C5B);
  static const Color _warmAmber = Color(0xFFFF8C42);
  static const Color _charcoal = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _orderManager.addListener(_onOrdersChanged);
    _orderManager.setLoading(true);
    _refreshOrders();
  }

  /// Loads the real orders from the server. The list survives an app restart
  /// and reflects what the vendor has actually confirmed.
  Future<void> _refreshOrders() async {
    _orderManager.setLoading(true);
    final serverOrders = await ApiService.getMyOrders();
    _orderManager.hydrate(serverOrders);
    _orderManager.setLoading(false);
  }

  @override
  void dispose() {
    _orderManager.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  /// Students cannot mark their own pickup complete — that was a loophole that
  /// let anyone clear stock without the vendor. This shows the pass instead and
  /// re-syncs with the server, so the status flips once the vendor verifies.
  void _showPickupPass(MysteryBoxOrder order) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Show This Code",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _tealPrimary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Text(
                order.pickupCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _tealPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "The shopkeeper enters this code to confirm your handover. "
              "Your order flips to Rescued once they do.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
        ],
      ),
    );
    // Re-sync in case the vendor confirmed while the pass was on screen.
    _refreshOrders();
  }

  void _showRatingDialog(MysteryBoxOrder order) {
    int selectedRating = 5;
    final List<String> feedbackTags = [
      "Fresh & Delicious",
      "Huge Savings",
      "Clean Packaging",
      "Friendly Staff"
    ];
    final Set<String> selectedTags = {"Fresh & Delicious", "Huge Savings"};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setRatingState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tealPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: _warmAmber, size: 36),
              ),
              const SizedBox(height: 10),
              Text(
                "Rate Your Rescue!",
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _charcoal,
                ),
              ),
              Text(
                "How was the surplus box from ${order.vendorName}?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 5 Star Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  final starNum = idx + 1;
                  return IconButton(
                    onPressed: () {
                      setRatingState(() {
                        selectedRating = starNum;
                      });
                    },
                    icon: Icon(
                      starNum <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _warmAmber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: feedbackTags.map((tag) {
                  final isTagSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    selected: isTagSelected,
                    selectedColor: _tealPrimary.withValues(alpha: 0.15),
                    checkmarkColor: _tealPrimary,
                    onSelected: (val) {
                      setRatingState(() {
                        if (val) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Skip"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _tealPrimary,
                    content: Text(
                      "⭐ Thank you! Your $selectedRating-star review builds campus food rescue trust.",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orderManager.activeOrders;
    final pastOrders = _orderManager.completedOrders;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          'My Food Rescues',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: _tealPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Environmental Impact Summary Bar ───
            _buildImpactSummaryBar(activeOrders.length, pastOrders.length),
            const SizedBox(height: 20),

            // Active Pickups Section Header
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _warmAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Ready for Pickup",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tealPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${activeOrders.length} active",
                    style: GoogleFonts.inter(
                      color: _tealPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activeOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _warmAmber.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.takeout_dining_rounded, size: 36, color: _warmAmber),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Active Pickups Right Now",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Surplus meals from campus bakeries & cafes are waiting for you at up to 70% off!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => StudentShell.switchTab(0),
                      icon: const Icon(Icons.explore_rounded, size: 18),
                      label: Text(
                        "Explore Mystery Boxes",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tealPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...activeOrders.map((order) => _buildActiveOrderCard(order)),

            const SizedBox(height: 32),

            // Past Pickups History Header
            Row(
              children: [
                const Icon(Icons.eco_rounded, size: 20, color: _tealPrimary),
                const SizedBox(width: 8),
                Text(
                  "Rescued Boxes Impact",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (pastOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: Text(
                    "Your completed food rescues and CO₂ savings will appear here.",
                    style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...pastOrders.map((order) => _buildPastOrderCard(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(MysteryBoxOrder order) {
    final savings = (order.originalValue - order.paidPrice).toStringAsFixed(0);
    final remainingMinutes = order.closingTime.difference(DateTime.now()).inMinutes;
    final isUrgent = remainingMinutes <= 30;
    final countdownText = remainingMinutes > 0 ? "$remainingMinutes mins left" : "Window ending soon";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: _tealPrimary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          // Banner strip with Live Countdown Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFFF3E0) : _tealPrimary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: isUrgent ? Colors.orange.shade200 : _tealPrimary.withValues(alpha: 0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.deepOrange.withValues(alpha: 0.15) : _tealPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUrgent ? Icons.alarm_on_rounded : Icons.timer_outlined,
                        size: 16,
                        color: isUrgent ? Colors.deepOrange : _tealPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup before ${order.closingTime.hour}:${order.closingTime.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: _charcoal,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "⏳ $countdownText",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: isUrgent ? Colors.deepOrange : _tealPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _warmAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Save ₹$savings",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.vendorName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Surplus Box • ${order.shopCategory}",
                            style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${order.paidPrice.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _tealPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 12),

                // Digital Pickup QR & Code Pass
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 56, color: _tealPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pickup Pass Code",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.pickupCode,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: _charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Show this code or QR at the counter",
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => StudentShell.switchTab(1),
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: Text(
                          "View Route",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _tealPrimary,
                          side: const BorderSide(color: _tealPrimary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPickupPass(order),
                          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                          label: Text(
                            "Show Pass",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tealPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrderCard(MysteryBoxOrder order) {
    return InkWell(
      // Tapping a rescued box lets the student rate that vendor — the rating
      // flow now has a real entry point instead of being unreachable.
      onTap: () => _showRatingDialog(order),
      borderRadius: BorderRadius.circular(18),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: _tealPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.vendorName,
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _charcoal,
                  ),
                ),
                Text(
                  "Rescued food • Paid ₹${order.paidPrice.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Rescued 🌱",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _tealPrimary,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildImpactSummaryBar(int activeCount, int pastCount) {
    // Real numbers from the hydrated orders — no invented per-box value.
    final impact = OrderManager().impact;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF006C5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006C5B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF80CBC4), size: 16),
              const SizedBox(width: 8),
              Text(
                "YOUR CAMPUS RESCUE IMPACT",
                style: GoogleFonts.inter(
                  color: const Color(0xFF80CBC4),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImpactStatItem("${impact.mealsRescued}", "Boxes Rescued"),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildImpactStatItem("₹${impact.moneySaved.toStringAsFixed(0)}", "Cash Saved"),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildImpactStatItem("${impact.co2AvoidedKg} kg", "CO₂ Avoided"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _orderManager.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    _orderManager.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  void _confirmPickup(MysteryBoxOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Pickup"),
        content: Text(
          "Did you collect your Mystery Box from ${order.vendorName}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes, Collected!"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.completeDeal(dealId: order.dealId, studentId: order.studentId);
      _orderManager.markOrderCollected(order.dealId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF006C5B),
            content: Text("🎉 Mystery Box collected from ${order.vendorName}! You saved ₹${(order.originalValue - order.paidPrice).toStringAsFixed(0)}!"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orderManager.activeOrders;
    final pastOrders = _orderManager.completedOrders;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Pickups & Passes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF006C5B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Pickups Section
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Ready for Pickup",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${activeOrders.length} active",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activeOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      "No Active Pickups",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Reserve a mystery box from the Discover or Map tab to generate a digital pickup pass.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => StudentShell.switchTab(0),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text("Explore Mystery Boxes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006C5B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...activeOrders.map((order) => _buildActiveOrderCard(order)),

            const SizedBox(height: 30),

            // Past Pickups History
            const Text(
              "Rescued Boxes History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (pastOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    "Your completed food rescues will appear here.",
                    style: TextStyle(color: Colors.grey[500]),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006C5B).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF006C5B).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF006C5B)),
                    const SizedBox(width: 6),
                    Text(
                      "Pickup before ${order.closingTime.hour}:${order.closingTime.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006C5B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Save ₹$savings",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.vendorName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Surplus Box • ${order.shopCategory}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      "₹${order.paidPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006C5B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Digital Pickup QR & Code
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFF006C5B)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pickup Verification Code",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.pickupCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Show this code or scan QR at the counter",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dual Action Buttons: View Route on Radar Map + Collected confirmation
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => StudentShell.switchTab(1),
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text("View Route"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF006C5B),
                          side: const BorderSide(color: Color(0xFF006C5B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmPickup(order),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("Collected!"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006C5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.vendorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "Rescued food • Paid ₹${order.paidPrice.toStringAsFixed(0)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Rescued 🌱",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

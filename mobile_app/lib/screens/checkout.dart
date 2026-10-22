import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/order_manager.dart';
import '../services/api_service.dart';
import '../widgets/common_ui.dart';
import 'student_shell.dart';

class CheckoutScreen extends StatefulWidget {
  final dynamic deal;
  final Map<String, dynamic> reservation;

  const CheckoutScreen({
    super.key,
    required this.deal,
    required this.reservation,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late int _timeLeft;
  final int _initialTotalTime = 300; // 5 minute standard Redis TTL
  Timer? _timer;
  bool _isProcessingPayment = false;
  String _selectedPaymentMethod = "UPI";

  /// Idempotency key: one per checkout attempt, reused on retry so a flaky
  /// connection can never create a second order for the same payment.
  late final String _requestId =
      'ck-${DateTime.now().microsecondsSinceEpoch}-${widget.deal['id']}';

  // SaveBite matte palette
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _tealPrimary = Color(0xFF006C5B);

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.reservation['expires_in_seconds'] ?? _initialTotalTime;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _showTimeExpiredDialog();
      }
    });
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_off_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Reservation Expired"),
          ],
        ),
        content: const Text(
          "Your 5-minute reservation hold has expired. The mystery box has been safely returned to live surplus inventory.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Back to Discover"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    final vendor = widget.deal['vendor'] ?? {};
    final paidPrice = (widget.reservation['reserved_price'] as num?)?.toDouble() ??
        (widget.deal['current_price'] as num?)?.toDouble() ??
        (widget.deal['start_price'] as num?)?.toDouble() ??
        180.0;
    final dealId = widget.deal['id'];

    // Call backend to permanently deduct stock in PostgreSQL and generate verified pickup code
    final orderRes = await ApiService.createOrder(
      dealId: dealId,
      clientRequestId: _requestId,
      paymentMethod: _selectedPaymentMethod,
    );

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = false;
    });

    _timer?.cancel();

    if (orderRes != null && orderRes['order_id'] != null) {
      final realPickupCode = orderRes['pickup_code'] ?? "SB-$dealId";
      final vendorDisplayName = orderRes['vendor_name'] ?? vendor['name'] ?? 'Mystery Box Partner';

      // Register the server-confirmed order (server is the authority)
      final orderPayload = orderRes['order'];
      if (orderPayload is Map<String, dynamic>) {
        OrderManager().addFromCreateResponse(orderPayload);
      } else if (orderPayload is Map) {
        OrderManager().addFromCreateResponse(Map<String, dynamic>.from(orderPayload));
      }

      // Show Celebration Bottom Sheet with verified passcode
      _showSuccessBottomSheet(realPickupCode, vendorDisplayName, paidPrice);
    } else {
      // Stock conflict or backend failure
      final msg = orderRes != null && orderRes['detail'] != null
          ? orderRes['detail'].toString()
          : "Inventory full or already claimed by another student. No payment was deducted.";
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text("Mystery Box Sold Out"),
            ],
          ),
          content: Text(msg),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Return to Discover"),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessBottomSheet(String pickupCode, String vendorName, double paidPrice) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Animated Success Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.2), width: 3),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF006C5B),
                size: 46,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              "Mystery Box Reserved! 🎉",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Your order is locked and ready for pickup at $vendorName.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 18),

            // Passcode Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 90, color: Color(0xFF006C5B)),
                  const SizedBox(height: 6),
                  Text(
                    "DIGITAL PICKUP PASS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      pickupCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF006C5B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Show this passcode or QR to cashier upon arrival",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Two Architectural Flow Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text("My Passes", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF006C5B)),
                      foregroundColor: const Color(0xFF006C5B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Close modal
                      Navigator.pop(context); // Close checkout
                      StudentShell.switchTab(2); // Jump to My Pickups
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions_walk_rounded, size: 18),
                    label: const Text("View Route", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF006C5B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Close modal
                      Navigator.pop(context); // Close checkout
                      StudentShell.switchTab(1); // Jump to Radar Map
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.deal['vendor'] ?? {};
    final vendorName = vendor['name'] ?? 'Mystery Box Partner';
    final category = vendor['shop_category'] ?? 'Surplus Treats';
    final boxTitle = widget.deal['title'] ?? '$vendorName Mystery Box';
    final dietaryTag = widget.deal['dietary_tag'] ?? '100% Pure Vegetarian';

    final reservedPrice = (widget.reservation['reserved_price'] as num?)?.toDouble() ??
        (widget.deal['start_price'] as num?)?.toDouble() ??
        180.0;
    final origValue = (widget.deal['original_value'] as num?)?.toDouble() ?? 420.0;
    final savings = (origValue - reservedPrice).clamp(0.0, 9999.0);
    final discountPct = origValue > 0 ? ((savings / origValue) * 100).round() : 50;

    // Progress percentage for 5 minute countdown
    final double progress = (_timeLeft / _initialTotalTime).clamp(0.0, 1.0);
    final isUrgent = _timeLeft < 60;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          "Reserve Mystery Box",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: _tealPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Where am I in the rescue journey — always visible above the fold.
          const FlowStepper(
            steps: ['Reserve', 'Pay', 'Collect'],
            currentStep: 1,
          ),

          const SizedBox(height: 16),

            // Ephemeral Lock Countdown Banner — spoken in customer language;
            // backing-store details stay out of the UI copy.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUrgent ? Colors.red.shade300 : const Color(0xFF006C5B).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_clock_rounded,
                            color: isUrgent ? Colors.red : const Color(0xFF006C5B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Box held only for you",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red.shade900 : const Color(0xFF006C5B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatTime(_timeLeft),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isUrgent ? Colors.red : const Color(0xFF006C5B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgent ? Colors.red : const Color(0xFF006C5B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your price is locked until the timer ends. Finish payment to guarantee today's remaining boxes.",
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006C5B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF006C5B), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendorName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "$category • $dietaryTag",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Mystery Box Line Item
                  Text(
                    boxTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Surplus assortment saved at closing • 100% freshly prepared today",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Bill Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Original Value", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        "₹$origValue",
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Surplus Decay Discount ($discountPct% OFF)",
                        style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "-₹${savings.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Green Campus Packaging Fee", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text("FREE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "₹$reservedPrice",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF006C5B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Options Selector
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: RadioGroup<String>(
                groupValue: _selectedPaymentMethod,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
                child: const Column(
                children: [
                  RadioListTile<String>(
                    value: "UPI",
                    activeColor: Color(0xFF006C5B),
                    title: Text("Instant UPI (GPay / PhonePe / Paytm)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Fast 1-tap test checkout simulator", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    secondary: Icon(Icons.bolt_rounded, color: Colors.amber),
                  ),
                  Divider(height: 1),
                  RadioListTile<String>(
                    value: "CARD",
                    activeColor: Color(0xFF006C5B),
                    title: Text("Debit / Credit Card / Netbanking", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    secondary: Icon(Icons.credit_card_rounded, color: Colors.grey),
                  ),
                ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_timeLeft > 0 && !_isProcessingPayment) ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isProcessingPayment
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text("Confirming UPI Payment...", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Pay ₹$reservedPrice & Lock Mystery Box",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

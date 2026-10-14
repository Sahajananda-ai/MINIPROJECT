import 'package:flutter/material.dart';
import 'dart:async';
import '../services/order_manager.dart';

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
  Timer? _timer;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.reservation['expires_in_seconds'] ?? 300;
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
        title: const Text("Time Expired"),
        content: const Text("Your reservation has expired. The mystery box has been returned to inventory."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to map
            },
            child: const Text("Back to Map"),
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

    // Mock UPI/payment gateway delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = false;
    });
    
    _timer?.cancel();

    // Register active order
    final vendor = widget.deal['vendor'] ?? {};
    final paidPrice = (widget.reservation['reserved_price'] as num?)?.toDouble() ?? 
        (widget.deal['start_price'] as num?)?.toDouble() ?? 120.0;
    final origVal = (widget.deal['original_value'] as num?)?.toDouble() ?? 400.0;
    final closing = DateTime.tryParse(widget.deal['closing_time']?.toString() ?? '') ?? 
        DateTime.now().add(const Duration(hours: 3));

    final lat = (vendor['latitude'] as num?)?.toDouble();
    final lng = (vendor['longitude'] as num?)?.toDouble();

    OrderManager().addOrder(
      dealId: widget.deal['id'] ?? 1,
      studentId: 1,
      vendorName: vendor['name'] ?? 'Mystery Box Partner',
      shopCategory: vendor['shop_category'] ?? 'Surplus Bag',
      paidPrice: paidPrice,
      originalValue: origVal,
      closingTime: closing,
      latitude: lat,
      longitude: lng,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Payment Confirmed! 🎉", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Your Mystery Box is officially reserved!",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF006C5B)),
                  const SizedBox(height: 8),
                  Text(
                    "PASS: MB-${widget.deal['id']}-LIVE",
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Show this QR pass or PIN at ${vendor['name'] ?? 'the store'} during pickup.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to Student home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("View My Orders"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.deal['vendor'];
    final reservedPrice = widget.reservation['reserved_price'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    "Complete payment within",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_timeLeft),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary
            const Text("Order Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront, size: 40, color: Colors.deepOrange),
              title: Text(vendor['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("1x Mystery Box (${vendor['shop_category']})"),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total to Pay", style: TextStyle(fontSize: 18)),
                Text(
                  "₹$reservedPrice",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_timeLeft > 0 && !_isProcessingPayment) ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        "Pay ₹$reservedPrice via UPI",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

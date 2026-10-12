import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'role_selection.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _originalValueController = TextEditingController(text: "400");
  final _startPriceController = TextEditingController(text: "200");
  final _minPriceController = TextEditingController(text: "120");
  final _quantityController = TextEditingController(text: "3");
  int _selectedHours = 4;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _presets = [
    {"title": "🥐 Bakery Bag", "orig": 400, "start": 200, "min": 120, "qty": 3},
    {"title": "☕ Cafe Treat", "orig": 250, "start": 120, "min": 80, "qty": 2},
    {"title": "🍛 Lunch Thali", "orig": 300, "start": 150, "min": 100, "qty": 4},
  ];

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _originalValueController.text = preset['orig'].toString();
      _startPriceController.text = preset['start'].toString();
      _minPriceController.text = preset['min'].toString();
      _quantityController.text = preset['qty'].toString();
    });
  }

  void _createDeal() async {
    final originalValue = double.tryParse(_originalValueController.text) ?? 0;
    final startPrice = double.tryParse(_startPriceController.text) ?? 0;
    final minPrice = double.tryParse(_minPriceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (originalValue <= 0 || startPrice <= 0 || minPrice <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid positive numbers.")),
      );
      return;
    }

    if (minPrice > startPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum price cannot exceed start price.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = false;
    try {
      success = await ApiService.createMysteryBox(
        vendorId: 1,
        originalValue: originalValue,
        startPrice: startPrice,
        minPrice: minPrice,
        quantity: quantity,
        closingTime: DateTime.now().add(Duration(hours: _selectedHours)),
      );
    } catch (e) {
      debugPrint("Error creating deal: $e");
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF006C5B),
          content: Text("🎉 Mystery Box ($quantity boxes) Listed! Students within 2km are being alerted!"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create deal. Ensure backend is running.")),
      );
    }
  }

  void _openRedeemDialog() {
    final TextEditingController dealIdCtrl = TextEditingController(text: "41");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF006C5B)),
            SizedBox(width: 8),
            Text("Redeem Pickup Pass", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the Student's Deal ID or scan their QR Pass to confirm pickup.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dealIdCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Deal ID (e.g. 41)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = int.tryParse(dealIdCtrl.text) ?? 1;
              final ok = await ApiService.completeDeal(dealId: id, studentId: 1);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? const Color(0xFF006C5B) : Colors.red,
                    content: Text(ok ? "✅ Customer pickup verified & order completed!" : "Failed to verify pickup pass."),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
            ),
            child: const Text("Verify & Handover"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _originalValueController.dispose();
    _startPriceController.dispose();
    _minPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vendor Partner Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006C5B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Redeem Student QR Pass',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openRedeemDialog,
          ),
          IconButton(
            tooltip: 'Switch to Student Mode',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.storefront_rounded, color: Color(0xFF006C5B), size: 28),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gupta Sweets & Bakery",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "FSSAI: 11519024000111 • ⭐ 5.0",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Title
            const Text(
              "Publish Mystery Box",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Rescue surplus food before closing. Prices dynamically decay to maximize sales.",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),

            const SizedBox(height: 16),

            // Quick Preset Buttons
            const Text("Quick Presets:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _presets.map((p) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => _applyPreset(p),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        p['title'],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputField(
                    label: "Original Value (₹)",
                    icon: Icons.currency_rupee,
                    controller: _originalValueController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: "Start Price (₹)",
                          icon: Icons.trending_down,
                          controller: _startPriceController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          label: "Min Floor (₹)",
                          icon: Icons.price_change,
                          controller: _minPriceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: "Quantity of Boxes",
                    icon: Icons.inventory_2_outlined,
                    controller: _quantityController,
                  ),
                  const SizedBox(height: 16),
                  // Closing Hours Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text("Listing Duration:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        DropdownButton<int>(
                          value: _selectedHours,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text("2 Hours")),
                            DropdownMenuItem(value: 4, child: Text("4 Hours")),
                            DropdownMenuItem(value: 6, child: Text("6 Hours")),
                            DropdownMenuItem(value: 8, child: Text("8 Hours")),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedHours = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createDeal,
                icon: const Icon(Icons.flash_on_rounded),
                label: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "List Mystery Box Now",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Secondary Quick Action
            Center(
              child: TextButton.icon(
                onPressed: _openRedeemDialog,
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF006C5B)),
                label: const Text(
                  "Customer Arrived? Verify Pickup Pass",
                  style: TextStyle(color: Color(0xFF006C5B), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF006C5B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}

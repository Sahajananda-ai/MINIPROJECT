import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  // Controllers to capture user input
  final _originalValueController = TextEditingController();
  final _startPriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    // Hardcoding vendorId to 1 and setting closing time to 4 hours from now for demo purposes.
    final success = await ApiService.createMysteryBox(
      vendorId: 1, 
      originalValue: originalValue,
      startPrice: startPrice,
      minPrice: minPrice,
      quantity: quantity,
      closingTime: DateTime.now().add(const Duration(hours: 4)),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mystery Box Listed Successfully!")),
      );
      _originalValueController.clear();
      _startPriceController.clear();
      _minPriceController.clear();
      _quantityController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create deal. Try again.")),
      );
    }
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
      backgroundColor: Colors.grey[50], // Very light background for contrast
      appBar: AppBar(
        title: const Text('Vendor Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              "Create a Mystery Box",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Turn your surplus food into revenue and reduce waste.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: "Start Price (₹)",
                          icon: Icons.trending_down,
                          controller: _startPriceController,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInputField(
                          label: "Min Price (₹)",
                          icon: Icons.price_change,
                          controller: _minPriceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: "Quantity of Boxes",
                    icon: Icons.inventory_2_outlined,
                    controller: _quantityController,
                  ),
                  const SizedBox(height: 20),
                  // Mock Time Picker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text("Closing Time", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          ],
                        ),
                        const Text("10:00 PM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createDeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Text(
                        "List Mystery Box Now",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build nice looking input fields
  Widget _buildInputField({required String label, required IconData icon, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}

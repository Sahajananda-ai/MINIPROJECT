import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/order_manager.dart';
import 'role_selection.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _originalValueController = TextEditingController(text: "420");
  final _startPriceController = TextEditingController(text: "210");
  final _minPriceController = TextEditingController(text: "120");
  final _quantityController = TextEditingController(text: "3");
  final _titleController = TextEditingController(text: "🥐 Midnight Boulangerie Secret Vault");
  final _descriptionController = TextEditingController(
    text: "A decadent surprise assortment of today's oven-fresh French viennoiseries and artisan bakes. Expect golden, flaky butter layers, comforting warm aromas, and delicate sweet and savory finishes hand-crafted by our master baker. 100% vegetarian surplus rescued at peak freshness!",
  );
  final _dietaryTagController = TextEditingController(text: "100% Pure Vegetarian • Contains Dairy");
  final _itemsHintController = TextEditingController(text: "3 chocolate croissants, 2 pain au chocolat, 1 almond puff");

  int _selectedHours = 4;
  String _selectedCategory = "Bakery";
  String? _coverImageUrl = "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80";
  bool _isLoading = false;
  bool _isAiCurating = false;

  // Selected surplus item photos (Used by AI to analyze, but hidden from customers)
  final List<Map<String, String>> _surplusItemPhotos = [
    {
      "name": "Butter Croissants",
      "url": "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&auto=format&fit=crop&q=80"
    },
    {
      "name": "Artisan Baguettes",
      "url": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80"
    },
    {
      "name": "Chocolate Bakes",
      "url": "https://images.unsplash.com/photo-1607958996333-41aef7caef4b?w=400&auto=format&fit=crop&q=80"
    },
  ];

  // Quick Preset Sample Food Photos for easy 1-tap testing
  final List<Map<String, dynamic>> _sampleSurplusTrays = [
    {
      "category": "Bakery",
      "title": "🥐 Bakery & Pastry Surplus",
      "itemsText": "3 chocolate croissants, 2 blueberry muffins, 1 puff",
      "orig": 420.0,
      "start": 210.0,
      "min": 120.0,
      "photos": [
        {"name": "Croissant", "url": "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&auto=format&fit=crop&q=80"},
        {"name": "Muffin", "url": "https://images.unsplash.com/photo-1607958996333-41aef7caef4b?w=400&auto=format&fit=crop&q=80"},
      ]
    },
    {
      "category": "Cafe",
      "title": "🥪 Cafe Panini & Sandwiches",
      "itemsText": "2 grilled vegetable paninis, 1 pesto wrap, 1 cookie",
      "orig": 360.0,
      "start": 180.0,
      "min": 110.0,
      "photos": [
        {"name": "Panini", "url": "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&auto=format&fit=crop&q=80"},
        {"name": "Wrap", "url": "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&auto=format&fit=crop&q=80"},
      ]
    },
    {
      "category": "Restaurant",
      "title": "🍛 Shahi Feast & Curries",
      "itemsText": "Paneer makhani, dal tadka, jeera rice, tandoori rotis",
      "orig": 350.0,
      "start": 175.0,
      "min": 100.0,
      "photos": [
        {"name": "Curry", "url": "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400&auto=format&fit=crop&q=80"},
        {"name": "Breads", "url": "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80"},
      ]
    },
    {
      "category": "Pizza",
      "title": "🍕 Woodfired Pizza Bakes",
      "itemsText": "3 margherita slices, 2 garlic breads, 1 calzone",
      "orig": 380.0,
      "start": 190.0,
      "min": 110.0,
      "photos": [
        {"name": "Pizza", "url": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&auto=format&fit=crop&q=80"},
      ]
    },
  ];

  void _loadSurplusTray(Map<String, dynamic> tray) {
    setState(() {
      _selectedCategory = tray['category'];
      _itemsHintController.text = tray['itemsText'];
      _originalValueController.text = tray['orig'].toString();
      _startPriceController.text = tray['start'].toString();
      _minPriceController.text = tray['min'].toString();
      _surplusItemPhotos.clear();
      for (var p in tray['photos']) {
        _surplusItemPhotos.add({"name": p['name'], "url": p['url']});
      }
    });
    // Trigger AI Vision curation automatically
    _generateAiMysteryDescription();
  }

  void _addCustomPhotoPrompt() {
    final textCtrl = TextEditingController(
      text: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&auto=format&fit=crop&q=80",
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF006C5B)),
            SizedBox(width: 8),
            Text("Add Item Photo URL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add photo of surplus food items from kitchen. The AI analyzes item qualities to craft the mystery description while keeping exact items hidden from customers.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                labelText: "Image URL",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006C5B)),
            onPressed: () {
              final url = textCtrl.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  _surplusItemPhotos.add({"name": "Surplus Item #${_surplusItemPhotos.length + 1}", "url": url});
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add Photo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _generateAiMysteryDescription() async {
    setState(() {
      _isAiCurating = true;
    });

    final itemNames = _surplusItemPhotos.map((p) => p['name'] ?? '').where((n) => n.isNotEmpty).toList();
    final itemsText = _itemsHintController.text.trim();

    final result = await ApiService.generateMysteryBoxDescription(
      category: _selectedCategory,
      itemsText: itemsText.isNotEmpty ? itemsText : null,
      itemsDetected: itemNames.isNotEmpty ? itemNames : null,
      imageUrl: _surplusItemPhotos.isNotEmpty ? _surplusItemPhotos.first['url'] : null,
    );

    if (!mounted) return;

    setState(() {
      _isAiCurating = false;
    });

    if (result != null && result['success'] == true) {
      setState(() {
        _titleController.text = result['mystery_title'] ?? _titleController.text;
        _descriptionController.text = result['mystery_description'] ?? _descriptionController.text;
        _dietaryTagController.text = result['dietary_tag'] ?? _dietaryTagController.text;
        _coverImageUrl = result['cover_image_url'] ?? _coverImageUrl;

        if (result['suggested_original_value'] != null) {
          _originalValueController.text = result['suggested_original_value'].toString();
        }
        if (result['suggested_start_price'] != null) {
          _startPriceController.text = result['suggested_start_price'].toString();
        }
        if (result['suggested_min_price'] != null) {
          _minPriceController.text = result['suggested_min_price'].toString();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF006C5B),
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "✨ AI Curated Mystery Description! (Specific items kept secret from customers)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI curation unavailable. Using existing description.")),
      );
    }
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
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dietaryTag: _dietaryTagController.text.trim(),
        imageUrl: _coverImageUrl,
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
          content: Text("🎉 Mystery Box '$quantity boxes' Listed! Students within 2km are being alerted!"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create deal. Ensure backend is running.")),
      );
    }
  }

  void _openRedeemDialog() {
    final TextEditingController passCodeCtrl = TextEditingController();
    String? dialogError;
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF006C5B), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Verify Customer Pickup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ask student to show their digital SaveBite pickup pass from their app.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Customer Pass Code (e.g. SB-4821)",
                      hintText: "Enter pass code",
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF006C5B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      errorText: dialogError,
                    ),
                    onChanged: (_) {
                      if (dialogError != null) {
                        setDialogState(() {
                          dialogError = null;
                        });
                      }
                    },
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogError!,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4C9B8)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF006C5B), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Ask the customer to show their SaveBite pickup pass. The code looks like: MB-41-7291",
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B5D52)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                icon: isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                label: Text(
                  isVerifying ? "Verifying..." : "Verify & Handover",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C5B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: isVerifying
                    ? null
                    : () async {
                        final input = passCodeCtrl.text.trim();
                        if (input.isEmpty) {
                          setDialogState(() {
                            dialogError = "Please enter customer's pickup code";
                          });
                          return;
                        }

                        setDialogState(() {
                          isVerifying = true;
                          dialogError = null;
                        });

                        // Call strict database verification API
                        final verifyRes = await ApiService.verifyPickupCode(
                          vendorId: 1,
                          pickupCode: input,
                        );

                        if (!ctx.mounted) return;

                        if (verifyRes['success'] == true) {
                          final orderData = verifyRes['order'] ?? {};
                          final dealId = (orderData['deal_id'] as num?)?.toInt() ?? 41;

                          OrderManager().markOrderCollected(dealId);
                          OrderManager().markOrderCollectedByCode(input);

                          Navigator.pop(ctx); // Close dialog

                          if (mounted) {
                            _showVerifiedSuccessDialog(orderData, input);
                          }
                        } else {
                          setDialogState(() {
                            isVerifying = false;
                            dialogError = verifyRes['message'] ?? "Invalid or already collected code";
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVerifiedSuccessDialog(Map<String, dynamic> order, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              "Pickup Verified!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Release mystery box to student now.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Pass Code:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006C5B))),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Student ID:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("Student #${order['student_id'] ?? '1'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Paid Value:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("₹${order['paid_price'] ?? '180'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C5B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Handover Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _originalValueController.dispose();
    _startPriceController.dispose();
    _minPriceController.dispose();
    _quantityController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dietaryTagController.dispose();
    _itemsHintController.dispose();
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

            const SizedBox(height: 24),

            // AI Mystery Vision & Curator Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006C5B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF006C5B), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Mystery Box Curator",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Add surplus items/photos • AI generates description keeping contents secret",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // AI Vision Box Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mystery Shield Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "🔒 Customer Mystery Shield Active: Photos and itemized names are analyzed by AI to craft an enticing description, but are KEPT HIDDEN from customers to preserve the mystery!",
                            style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Sample Surplus Trays
                  const Text(
                    "Quick Surplus Photo Presets:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sampleSurplusTrays.map((tray) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF006C5B)),
                            label: Text(tray['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.grey[100],
                            onPressed: () => _loadSurplusTray(tray),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Surplus Item Photos Gallery
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Surplus Item Photos (${_surplusItemPhotos.length}):",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                        label: const Text("Add Photo URL", style: TextStyle(fontSize: 12)),
                        onPressed: _addCustomPhotoPrompt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _surplusItemPhotos.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == _surplusItemPhotos.length) {
                          return InkWell(
                            onTap: _addCustomPhotoPrompt,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 24),
                                  SizedBox(height: 4),
                                  Text("Add Item", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        }

                        final photo = _surplusItemPhotos[index];
                        return Stack(
                          children: [
                            Container(
                              width: 85,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.3)),
                                image: DecorationImage(
                                  image: NetworkImage(photo['url']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _surplusItemPhotos.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  photo['name'] ?? 'Item',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Optional notes / surplus item names for AI
                  TextField(
                    controller: _itemsHintController,
                    decoration: InputDecoration(
                      labelText: "Surplus Items in Kitchen (For AI Vision only)",
                      hintText: "e.g., 3 chocolate croissants, 2 pain au chocolat, muffins",
                      prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // AI Curate Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isAiCurating ? null : _generateAiMysteryDescription,
                      icon: _isAiCurating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, color: Colors.amber),
                      label: Text(
                        _isAiCurating ? "AI Analyzing Photos & Curating..." : "✨ Generate AI Mystery Description",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006C5B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Title
            const Text(
              "Review & Publish Mystery Box",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Below is what customers will see in the app. Exact surplus items remain a thrilling surprise!",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),

            const SizedBox(height: 16),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mystery Box Title (Customer Facing)
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Mystery Box Public Title",
                      prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF006C5B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mystery Description (Customer Facing - No items revealed)
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Customer Mystery Description (Keeps exact items secret)",
                      helperText: "Appetizing description emphasizing freshness, artisanal bake & value",
                      prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF006C5B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dietary Tag
                  TextField(
                    controller: _dietaryTagController,
                    decoration: InputDecoration(
                      labelText: "Dietary & Freshness Badge",
                      prefixIcon: const Icon(Icons.eco_outlined, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                    label: "Quantity of Boxes Available",
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

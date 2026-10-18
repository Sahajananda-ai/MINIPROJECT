import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkout.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _deals = [];
  bool _isLoading = true;

  final List<Map<String, String>> _categories = const [
    {'name': 'All', 'icon': '🌟'},
    {'name': 'Bakery', 'icon': '🥐'},
    {'name': 'Cafe', 'icon': '☕'},
    {'name': 'Meals', 'icon': '🍛'},
    {'name': 'Groceries', 'icon': '🍎'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final deals = await ApiService.getActiveDeals();
      if (mounted) {
        setState(() {
          _deals = deals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredDeals {
    return _deals.where((deal) {
      final vendor = deal['vendor'] ?? {};
      final name = (vendor['name'] ?? '').toString().toLowerCase();
      final category = (vendor['shop_category'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty || name.contains(query) || category.contains(query);
      final matchesCategory = _selectedCategory == 'All' || category.contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _getImageForCategory(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('bakery') || cat.contains('sweet')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop';
    }
    if (cat.contains('cafe') || cat.contains('coffee')) {
      return 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=800&auto=format&fit=crop';
    }
    if (cat.contains('grocery') || cat.contains('fruit')) {
      return 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?q=80&w=800&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop';
  }

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _AiAssistantModal(),
    );
  }

  void _openDealDetails(dynamic deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _DealDetailsSheet(deal: deal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDeals;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDeals,
        color: const Color(0xFF006C5B),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Sliver App Bar Header
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mystery Box Rescue',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '📍 North Campus • 2km Hyperlocal Feed',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF006C5B), Color(0xFF0A8A76)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24, top: 20),
                      child: Icon(
                        Icons.lunch_dining_rounded,
                        size: 90,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'SaveBite AI Assistant',
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
                  onPressed: _openAiAssistant,
                ),
              ],
            ),

            // Top Search & AI Prompt Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    // AI Assistant Banner Chip
                    GestureDetector(
                      onTap: _openAiAssistant,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade100, Colors.orange.shade50],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade400, width: 1.2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.deepOrange, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "SaveBite AI: Find the highest surplus savings for your budget!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.deepOrange),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search bakeries, cafes, meal boxes...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF006C5B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Categories Selector
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text("${cat['icon']} ${cat['name']}"),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat['name']!;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF006C5B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF006C5B) : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Deals List Section
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF006C5B)),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? "No surplus matches for '$_searchQuery'"
                            : "No active mystery boxes right now",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Check back closer to store closing hours or explore the Map!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final deal = filtered[index];
                    return _buildMysteryBoxCard(context, deal);
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildMysteryBoxCard(BuildContext context, dynamic deal) {
    final vendor = deal['vendor'] ?? {};
    final originalValue = deal['original_value']?.toString() ?? '400';
    final currentPrice = deal['start_price']?.toString() ?? '180';
    final vendorName = vendor['name'] ?? 'Local Surplus Partner';
    final category = vendor['shop_category'] ?? 'Bakery';
    final rating = vendor['rating']?.toString() ?? '4.9';

    final String title = deal['title'] ?? 'Surplus Mystery Box';
    final String? coverUrl = deal['image_url'];
    final String dietaryTag = deal['dietary_tag'] ?? '100% Pure Vegetarian';

    final double orig = double.tryParse(originalValue) ?? 400;
    final double curr = double.tryParse(currentPrice) ?? 180;
    final int discount = orig > 0 ? (((orig - curr) / orig) * 100).round() : 50;

    return GestureDetector(
      onTap: () => _openDealDetails(deal),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Image.network(
                      (coverUrl != null && coverUrl.isNotEmpty) ? coverUrl : _getImageForCategory(category),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF006C5B).withValues(alpha: 0.1),
                        child: const Icon(Icons.fastfood_rounded, size: 50, color: Color(0xFF006C5B)),
                      ),
                    ),
                  ),

                  // Discount Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "SAVE $discount%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Live Status Pill
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Live Decay Price',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Curated Badge
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF006C5B), size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "AI Curated Mystery • $dietaryTag",
                                style: const TextStyle(
                                  color: Color(0xFF006C5B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(vendorName, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            const SizedBox(width: 6),
                            const Text("•", style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            Text(" $rating", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹$originalValue',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹$currentPrice',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006C5B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealDetailsSheet extends StatefulWidget {
  final dynamic deal;
  const _DealDetailsSheet({required this.deal});

  @override
  State<_DealDetailsSheet> createState() => _DealDetailsSheetState();
}

class _DealDetailsSheetState extends State<_DealDetailsSheet> {
  bool _isReserving = false;

  void _reserve() async {
    setState(() {
      _isReserving = true;
    });

    final res = await ApiService.reserveDeal(
      dealId: widget.deal['id'],
      studentId: 1,
    );

    if (!mounted) return;

    setState(() {
      _isReserving = false;
    });

    if (res != null && res['success'] == true) {
      Navigator.pop(context); // Close sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            deal: widget.deal,
            reservation: res,
          ),
        ),
      );
    } else {
      final msg = res != null ? res['detail'] ?? res['message'] : "Failed to reserve deal.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.deal['vendor'] ?? {};
    final originalValue = widget.deal['original_value']?.toString() ?? '400';
    final currentPrice = widget.deal['start_price']?.toString() ?? '180';
    final vendorName = vendor['name'] ?? 'Mystery Box Partner';
    final category = vendor['shop_category'] ?? 'Bakery';
    final title = widget.deal['title'] ?? '$vendorName Mystery Box';
    final description = widget.deal['description'] ??
        "A surprise assortment of today's surplus freshly prepared food. Safe, delicious, and eco-friendly!";
    final dietaryTag = widget.deal['dietary_tag'] ?? '100% Pure Vegetarian';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // AI Badge & Dietary Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006C5B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF006C5B), size: 13),
                    SizedBox(width: 4),
                    Text(
                      "AI Mystery Curated",
                      style: TextStyle(color: Color(0xFF006C5B), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dietaryTag,
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "FSSAI Verified",
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("By $vendorName • $category", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // Sensory Description (No items revealed)
          const Row(
            children: [
              Icon(Icons.psychology_alt_outlined, color: Color(0xFF006C5B), size: 18),
              SizedBox(width: 6),
              Text(
                "Curated Mystery Sensory Notes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),

          // Mystery Protection Guarantee Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_clock_outlined, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Surplus Mystery Guarantee: Exact items remain secret until collection to keep prices over 50% off and prevent kitchen food waste. All items are freshly prepared today and 100% food safety inspected!",
                    style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Original Value", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      "₹$originalValue",
                      style: const TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Surplus Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      "₹$currentPrice",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF006C5B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Reserve Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isReserving ? null : _reserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isReserving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Reserve Mystery Box",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AiAssistantModal extends StatefulWidget {
  const _AiAssistantModal();

  @override
  State<_AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<_AiAssistantModal> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _aiResult;

  final List<String> _quickPrompts = const [
    "Under ₹150 snack",
    "Sweet bakery treats",
    "Hearty meal dinner",
    "Best value deal",
  ];

  void _askAi(String query) async {
    setState(() {
      _isLoading = true;
      _promptController.text = query;
    });

    final res = await ApiService.getAiRecommendation(query: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _aiResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.deepOrange, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                "SaveBite AI Surplus Assistant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Ask our AI to match you with the best surplus box for your taste and budget.",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Quick Prompt Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((p) {
              return ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onPressed: () => _askAi(p),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF006C5B)),
              ),
            )
          else if (_aiResult != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF006C5B).withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF006C5B).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_alt_rounded, color: Color(0xFF006C5B), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "AI Recommendation",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006C5B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiResult!['ai_insight'] ?? "Recommendation prepared.",
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

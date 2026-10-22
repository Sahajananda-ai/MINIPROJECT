import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/deal_pricing.dart';
import '../services/order_manager.dart';
import '../theme/savebite_theme.dart';
import '../widgets/common_ui.dart';
import 'checkout.dart';
import 'student_shell.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _selectedCategory = 'All';
  String _selectedDietary = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _deals = [];
  bool _isLoading = true;

  /// Distinguishes "no deals exist" from "the connection failed" so the feed
  /// can show a retry path instead of an apparently empty campus.
  bool _loadFailed = false;

  final List<Map<String, String>> _categories = const [
    {'name': 'All', 'icon': '🌟'},
    {'name': 'Bakery', 'icon': '🥐'},
    {'name': 'Cafe', 'icon': '☕'},
    {'name': 'Meals', 'icon': '🍛'},
    {'name': 'Groceries', 'icon': '🍎'},
  ];

  final List<Map<String, String>> _dietaryFilters = const [
    {'name': 'All', 'label': '✨ All Diets'},
    {'name': 'Pure Veg', 'label': '🌱 100% Pure Veg'},
    {'name': 'Vegan', 'label': '🥛 Vegan Safe'},
    {'name': 'Jain-Friendly', 'label': '🧅 Jain Friendly'},
  ];

  final OrderManager _orderManager = OrderManager();

  @override
  void initState() {
    super.initState();
    _orderManager.addListener(_onOrderStateChanged);
    _loadDeals();
  }

  void _onOrderStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orderManager.removeListener(_onOrderStateChanged);
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
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
          _loadFailed = true;
        });
      }
    }
  }

  List<dynamic> get _filteredDeals {
    return _deals.where((deal) {
      final vendor = deal['vendor'] ?? {};
      final name = (vendor['name'] ?? '').toString().toLowerCase();
      final category = (vendor['shop_category'] ?? '').toString().toLowerCase();
      final dietaryTag = (deal['dietary_tag'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty || name.contains(query) || category.contains(query);
      final matchesCategory = _selectedCategory == 'All' || category.contains(_selectedCategory.toLowerCase());
      final matchesDietary = _selectedDietary == 'All' ||
          dietaryTag.contains(_selectedDietary.toLowerCase()) ||
          (_selectedDietary == 'Pure Veg' && (dietaryTag.contains('veg') || dietaryTag.contains('vegetarian')));

      return matchesSearch && matchesCategory && matchesDietary;
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
      backgroundColor: const Color(0xFFF5F0E8),
      body: RefreshIndicator(
        onRefresh: _loadDeals,
        color: const Color(0xFF006C5B),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Sliver App Bar Header — TGTG warm cream style
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              backgroundColor: const Color(0xFF006C5B),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SaveBite',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '📍 North Campus • 2km Hyperlocal Feed',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF006C5B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: 20,
                        child: Icon(
                          Icons.eco_rounded,
                          size: 130,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Positioned(
                        right: 60,
                        bottom: 40,
                        child: Icon(
                          Icons.lunch_dining_rounded,
                          size: 70,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'SaveBite AI Assistant',
                    icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF8C42), size: 22),
                    onPressed: _openAiAssistant,
                  ),
                ),
              ],
            ),

            // Top Search & AI Prompt Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    // How It Works / Active Rescue Stepper
                    _buildHowItWorksOrActiveTracker(),

                    const SizedBox(height: 12),

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
                height: 44,
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
                          fontSize: 12,
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

            // Horizontal Dietary Shield Chips (Pure Veg / Vegan / Jain-Friendly)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dietaryFilters.length,
                    itemBuilder: (context, index) {
                      final diet = _dietaryFilters[index];
                      final isSelected = _selectedDietary == diet['name'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(diet['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDietary = diet['name']!;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF2E7D32),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.green.shade900,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 11,
                          ),
                          backgroundColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.green.shade200,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Deals List Section
            if (_isLoading)
              // Skeleton deal cards keep the layout stable while the feed loads —
              // a bare spinner made the app feel broken during fetches.
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const DealCardSkeleton(),
                  childCount: 3,
                ),
              )
            else if (_loadFailed)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorState(
                  message:
                      'Couldn\'t reach the live surplus feed. Check your connection and try again — deals update in real time, so nothing has been missed.',
                  onRetry: _loadDeals,
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.soup_kitchen_outlined,
                  iconColor: SaveBiteTheme.warmAmber,
                  title: _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedDietary != 'All'
                      ? 'No boxes match your filters'
                      : 'No active mystery boxes right now',
                  subtitle: _searchQuery.isNotEmpty ||
                          _selectedCategory != 'All' ||
                          _selectedDietary != 'All'
                      ? 'Fresh surplus drops all day as shops approach closing time. Try clearing your filters — or explore what\'s nearby on the map.'
                      : 'Check back closer to store closing hours, or look at the live radar map — the nearest shop may be baking right now!',
                  ctaLabel: 'Open Radar Map',
                  ctaIcon: Icons.map_outlined,
                  onCta: () => StudentShell.switchTab(1),
                  secondaryLabel: (_searchQuery.isNotEmpty ||
                          _selectedCategory != 'All' ||
                          _selectedDietary != 'All')
                      ? 'Clear filters'
                      : null,
                  onSecondary: (_searchQuery.isNotEmpty ||
                          _selectedCategory != 'All' ||
                          _selectedDietary != 'All')
                      ? () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'All';
                            _selectedDietary = 'All';
                          });
                        }
                      : null,
                ),
              )
            else ...[
              // Section header gives the feed a clear identity and shows how
              // many boxes are actually live right now.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: SectionHeader(
                    icon: Icons.bolt_rounded,
                    title: 'Live Surplus Near You',
                    trailing: '${filtered.length} live',
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final deal = filtered[index];
                    return _buildMysteryBoxCard(context, deal);
                  },
                  childCount: filtered.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildMysteryBoxCard(BuildContext context, dynamic deal) {
    final vendor = deal['vendor'] ?? {};
    final originalValue = ((deal['original_value'] as num?)?.toDouble() ?? 400).toStringAsFixed(0);
    final currentPrice = livePriceOf(deal, fallback: 180).toStringAsFixed(0);
    final vendorName = vendor['name'] ?? 'Local Surplus Partner';
    final category = vendor['shop_category'] ?? 'Bakery';
    final rating = vendor['rating']?.toString() ?? '4.9';

    final String title = deal['title'] ?? 'Surplus Mystery Box';
    final String? coverUrl = deal['image_url'];
    final String dietaryTag = deal['dietary_tag'] ?? '100% Pure Vegetarian';

    // Live discount against the shop's normal value — server-computed when
    // available so the badge never disagrees with the price shown.
    final int discount = discountPercentOf(deal);

    final int quantity = (deal['quantity'] as num?)?.toInt() ?? 0;
    final bool isSoldOut = quantity <= 0;

    return GestureDetector(
      onTap: () {
        if (isSoldOut) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.grey.shade900,
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "'$title' is Sold Out! Fresh surplus drops closer to closing hours.",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
          return;
        }
        _openDealDetails(deal);
      },
      child: Opacity(
        opacity: isSoldOut ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSoldOut ? Colors.grey.shade300 : const Color(0xFFEDE8E1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSoldOut ? 0.02 : 0.05),
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

                    if (isSoldOut)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white70, width: 1.5),
                              ),
                              child: const Text(
                                "SOLD OUT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Discount Badge
                    if (!isSoldOut)
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

                    // Live Status Pill / Remaining Stock Pill
                    Positioned(
                      top: 14,
                      right: 14,
                      child: isSoldOut
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '0 Available',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: quantity <= 3 ? Colors.deepOrange.shade700 : Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    quantity <= 3 ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    quantity <= 3 ? 'Only $quantity left!' : 'Live Decay Price',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSoldOut ? Colors.grey : const Color(0xFF006C5B),
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
      ),
    );
  }

  Widget _buildHowItWorksOrActiveTracker() {
    final activeOrders = _orderManager.activeOrders;
    if (activeOrders.isNotEmpty) {
      final active = activeOrders.first;
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFF1F8E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.3)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF006C5B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ACTIVE FOOD RESCUE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF006C5B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    active.pickupCode,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF006C5B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Collect from ${active.vendorName}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Show your digital pass or QR code at counter • ₹${active.paidPrice.toStringAsFixed(0)} paid",
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            // Progress Bar Steps
            Row(
              children: [
                _buildTrackerStep("Reserved", true),
                _buildTrackerLine(true),
                _buildTrackerStep("Heading to Store", true),
                _buildTrackerLine(false),
                _buildTrackerStep("Handover", false),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions_walk_rounded, size: 16),
                    label: const Text("View Route on Radar Map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C5B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      StudentShell.switchTab(1); // Jump to Radar Map
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF006C5B),
                    side: const BorderSide(color: Color(0xFF006C5B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    StudentShell.switchTab(2); // Jump to My Pickups
                  },
                  child: const Text("Show Pass", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default: Clean 3-Step "How SaveBite Works" Guide
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.eco_rounded, color: Color(0xFF006C5B), size: 16),
                  SizedBox(width: 6),
                  Text(
                    "HOW SAVEBITE WORKS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(0xFF006C5B),
                    ),
                  ),
                ],
              ),
              Text(
                "3 Easy Steps",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStepCard("1. Discover", "50-70% OFF", Icons.storefront_rounded)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              ),
              Expanded(child: _buildStepCard("2. Reserve", "5-Min Lock", Icons.lock_clock_rounded)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              ),
              Expanded(child: _buildStepCard("3. Collect", "QR Passcode", Icons.qr_code_2_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerStep(String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isDone ? const Color(0xFF006C5B) : Colors.grey[300],
            child: Icon(
              isDone ? Icons.check_rounded : Icons.circle,
              size: 11,
              color: isDone ? Colors.white : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? const Color(0xFF006C5B) : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerLine(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      color: isDone ? const Color(0xFF006C5B) : Colors.grey[300],
    );
  }

  Widget _buildStepCard(String step, String subtext, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF006C5B), size: 18),
          const SizedBox(height: 4),
          Text(
            step,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          Text(
            subtext,
            style: TextStyle(color: Colors.grey[600], fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
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
    final int dealId = (widget.deal['id'] as num?)?.toInt() ?? 0;
    final int quantity = (widget.deal['quantity'] as num?)?.toInt() ?? 0;

    // Guard 1: Check local quantity from the fetched deal data
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sorry, this mystery box is already sold out!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Guard 2: Check if student already has an active order for this deal
    if (OrderManager().hasActiveOrderForDeal(dealId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already have an active reservation for this box! Check your Orders tab."),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    setState(() {
      _isReserving = true;
    });

    final res = await ApiService.reserveDeal(dealId: dealId);

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
      // Handle 409 (sold out) or other backend errors clearly
      final msg = res != null
          ? (res['detail'] ?? res['message'] ?? "Failed to reserve deal.")
          : "Backend unreachable. Please check connection.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.deal['vendor'] ?? {};
    final originalValue = ((widget.deal['original_value'] as num?)?.toDouble() ?? 400).toStringAsFixed(0);
    final currentPrice = livePriceOf(widget.deal, fallback: 180).toStringAsFixed(0);
    final vendorName = vendor['name'] ?? 'Mystery Box Partner';
    final category = vendor['shop_category'] ?? 'Bakery';
    final title = widget.deal['title'] ?? '$vendorName Mystery Box';
    final description = widget.deal['description'] ??
        "A surprise assortment of today's surplus freshly prepared food. Safe, delicious, and eco-friendly!";
    final dietaryTag = widget.deal['dietary_tag'] ?? '100% Pure Vegetarian';

    final int quantity = (widget.deal['quantity'] as num?)?.toInt() ?? 0;
    final bool isSoldOut = quantity <= 0;

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
          // AI Badge & Dietary Tag (Wrap so long dietary tags never overflow)
          Wrap(
            spacing: 8,
            runSpacing: 6,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dietaryTag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),

          // Stock Availability Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSoldOut
                  ? Colors.grey.shade100
                  : (quantity <= 3 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSoldOut
                    ? Colors.grey.shade300
                    : (quantity <= 3 ? Colors.orange.shade300 : Colors.green.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSoldOut
                      ? Icons.do_not_disturb_on_rounded
                      : (quantity <= 3 ? Icons.local_fire_department_rounded : Icons.inventory_2_rounded),
                  color: isSoldOut
                      ? Colors.grey
                      : (quantity <= 3 ? Colors.deepOrange : const Color(0xFF006C5B)),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSoldOut
                        ? "Sold Out: All surplus boxes have been claimed for today."
                        : (quantity <= 3
                            ? "High Demand! Only $quantity mystery boxes remaining."
                            : "$quantity mystery boxes available today"),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSoldOut
                          ? Colors.grey.shade700
                          : (quantity <= 3 ? Colors.deepOrange.shade900 : const Color(0xFF006C5B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

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
              onPressed: (_isReserving || isSoldOut) ? null : _reserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSoldOut ? Colors.grey.shade400 : const Color(0xFF006C5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isReserving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      isSoldOut ? "Sold Out • 0 Left" : "Reserve Mystery Box",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                color: const Color(0xFF006C5B).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF006C5B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_alt_rounded, color: Color(0xFF006C5B), size: 20),
                      SizedBox(width: 8),
                      Text(
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

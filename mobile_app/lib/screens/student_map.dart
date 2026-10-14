import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/order_manager.dart';
import 'checkout.dart';
import 'student_orders.dart';

class StudentMapScreen extends StatefulWidget {
  const StudentMapScreen({super.key});

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final OrderManager _orderManager = OrderManager();

  // Default campus fallback coordinates (Central Campus Hub)
  LatLng _currentLocation = const LatLng(28.6139, 77.2090);
  bool _hasRealLocation = false;

  List<dynamic> _deals = [];
  bool _isLoading = true;
  dynamic _selectedDeal;
  MysteryBoxOrder? _selectedPickupOrder;

  @override
  void initState() {
    super.initState();
    _orderManager.addListener(_onOrdersChanged);
    _initLocationAndDeals();
  }

  @override
  void dispose() {
    _orderManager.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initLocationAndDeals() async {
    // 1. Fetch user's real GPS coordinates with fallback
    try {
      final position = await _locationService.determinePosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _hasRealLocation = true;
        });
        _mapController.move(_currentLocation, 14.2);
        // Sync student location with PostGIS backend for geofencing
        ApiService.updateStudentLocation(
          studentId: 1,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      debugPrint("Using default campus location: $e");
    }

    // 2. Fetch live deals
    await _fetchDeals();
  }

  Future<void> _fetchDeals() async {
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

  /// Calculates or normalizes the shop's LatLng so that demo shops registered
  /// with default coordinates are always placed right in the student's campus radius.
  LatLng _getShopLatLng(dynamic vendor, int index) {
    final double rawLat = (vendor?['latitude'] as num?)?.toDouble() ?? 28.6139;
    final double rawLng = (vendor?['longitude'] as num?)?.toDouble() ?? 77.2090;

    const Distance distance = Distance();
    final double distKm = distance.as(LengthUnit.Kilometer, _currentLocation, LatLng(rawLat, rawLng));

    // If the vendor is already near the student (< 10km), use their true coordinates
    if (distKm <= 10.0) {
      return LatLng(rawLat, rawLng);
    }

    // Otherwise, anchor the shop realistically within 250m - 700m of the student's current location!
    final List<List<double>> offsets = [
      [0.0032, 0.0035],   // ~420m Northeast
      [-0.0028, 0.0039],  // ~380m Southeast
      [0.0041, -0.0030],  // ~490m Northwest
      [-0.0035, -0.0034], // ~450m Southwest
      [0.0019, 0.0052],   // ~550m East
    ];
    final offset = offsets[index % offsets.length];
    return LatLng(_currentLocation.latitude + offset[0], _currentLocation.longitude + offset[1]);
  }

  LatLng _getOrderLatLng(MysteryBoxOrder order, int index) {
    const Distance distance = Distance();
    final double distKm = distance.as(LengthUnit.Kilometer, _currentLocation, LatLng(order.latitude, order.longitude));

    if (distKm <= 10.0) {
      return LatLng(order.latitude, order.longitude);
    }

    // Place active pickup shop ~350m from student
    return LatLng(_currentLocation.latitude + 0.0028, _currentLocation.longitude + 0.0031);
  }

  void _recenterToUser() {
    _mapController.move(_currentLocation, 14.5);
  }

  double _calculateDistanceKm(LatLng target) {
    const Distance distance = Distance();
    return double.parse(
      distance.as(LengthUnit.Kilometer, _currentLocation, target).toStringAsFixed(1),
    );
  }

  IconData _getCategoryIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('bakery') || cat.contains('cake') || cat.contains('sweet')) {
      return Icons.bakery_dining_rounded;
    }
    if (cat.contains('cafe') || cat.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (cat.contains('grocery') || cat.contains('fruit')) {
      return Icons.local_grocery_store_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orderManager.activeOrders;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Surplus Food Radar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: [
                Icon(
                  _hasRealLocation ? Icons.my_location : Icons.location_city,
                  size: 12,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  _hasRealLocation ? 'GPS Campus Live' : 'Campus Hub (2km Radius)',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C5B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Deals',
            onPressed: _fetchDeals,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.2,
              onTap: (tapPosition, point) {
                if (_selectedDeal != null || _selectedPickupOrder != null) {
                  setState(() {
                    _selectedDeal = null;
                    _selectedPickupOrder = null;
                  });
                }
              },
            ),
            children: [
              // OpenStreetMap Carto-style tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mystery_box_app',
              ),

              // 2km Spatial Geofence Zone Circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentLocation,
                    radius: 2000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF006C5B).withValues(alpha: 0.08),
                    borderColor: const Color(0xFF006C5B).withValues(alpha: 0.4),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // Polyline connecting student to their active pickup store!
              if (activeOrders.isNotEmpty)
                PolylineLayer(
                  polylines: activeOrders.asMap().entries.map((entry) {
                    final shopPoint = _getOrderLatLng(entry.value, entry.key);
                    return Polyline(
                      points: [_currentLocation, shopPoint],
                      color: Colors.deepOrange.withValues(alpha: 0.8),
                      strokeWidth: 3.5,
                      isDotted: true,
                    );
                  }).toList(),
                ),

              // Markers Layer: Student Beacon + Vendor Deal Markers + Active Purchased Orders
              MarkerLayer(
                markers: [
                  // 1. Student Current Location Beacon
                  Marker(
                    point: _currentLocation,
                    width: 70,
                    height: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.person_pin, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Active Purchased Order Pickup Pins (Highest Priority)
                  ...activeOrders.asMap().entries.map((entry) {
                    final order = entry.value;
                    final shopPoint = _getOrderLatLng(order, entry.key);
                    final isSelected = _selectedPickupOrder?.dealId == order.dealId;

                    return Marker(
                      point: shopPoint,
                      width: 120,
                      height: 85,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPickupOrder = order;
                            _selectedDeal = null;
                          });
                          _mapController.move(shopPoint, 15.0);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : Colors.green.shade700,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "COLLECT HERE",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isSelected ? Colors.deepOrange : Colors.green.shade700,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // 3. Active Listed Mystery Box Vendor Pins
                  ..._deals.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final deal = entry.value;
                    final vendor = deal['vendor'] ?? {};
                    final shopPoint = _getShopLatLng(vendor, idx);
                    final String category = vendor['shop_category'] ?? 'Food';
                    final price = deal['start_price']?.toString() ?? '180';
                    final isSelected = _selectedDeal != null && _selectedDeal['id'] == deal['id'];

                    return Marker(
                      point: shopPoint,
                      width: 95,
                      height: 75,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDeal = deal;
                            _selectedPickupOrder = null;
                          });
                          _mapController.move(shopPoint, 15.0);
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : const Color(0xFF006C5B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getCategoryIcon(category), color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "₹$price",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isSelected ? Colors.deepOrange : const Color(0xFF006C5B),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Active Order Notification Banner
          if (activeOrders.isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  final order = activeOrders.first;
                  final shopPoint = _getOrderLatLng(order, 0);
                  _mapController.move(shopPoint, 15.5);
                  setState(() {
                    _selectedPickupOrder = order;
                    _selectedDeal = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.green, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "1 Mystery Box Ready for Pickup!",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                            Text(
                              "${activeOrders.first.vendorName} • Tap to view shop route",
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("Scanning campus for surplus boxes..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Floating Recenter Button
          Positioned(
            right: 16,
            bottom: (_selectedDeal != null || _selectedPickupOrder != null) ? 220 : 30,
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006C5B),
              onPressed: _recenterToUser,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Preview Card for Active Listed Deal
          if (_selectedDeal != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildDealPreviewCard(_selectedDeal),
            ),

          // Bottom Preview Card for Active Purchased Pickup Order
          if (_selectedPickupOrder != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildPickupOrderCard(_selectedPickupOrder!),
            ),
        ],
      ),
    );
  }

  Widget _buildDealPreviewCard(dynamic deal) {
    final vendor = deal['vendor'] ?? {};
    final shopPoint = _getShopLatLng(vendor, 0);
    final distance = _calculateDistanceKm(shopPoint);
    final originalPrice = deal['original_value']?.toString() ?? '400';
    final currentPrice = deal['start_price']?.toString() ?? '180';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['name'] ?? 'Mystery Box Partner',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          vendor['shop_category'] ?? 'Bakery',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        const Text("•", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        Icon(Icons.near_me_rounded, size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          "$distance km away",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDeal = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹$originalPrice",
                    style: TextStyle(
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[400],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "₹$currentPrice",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006C5B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Surplus Save",
                          style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _ReserveButton(deal: deal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupOrderCard(MysteryBoxOrder order) {
    final shopPoint = _getOrderLatLng(order, 0);
    final distance = _calculateDistanceKm(shopPoint);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.vendorName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Pickup Point • $distance km away",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _selectedPickupOrder = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pickup Pass Code", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      order.pickupCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentOrdersScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text("View Pass"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C5B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReserveButton extends StatefulWidget {
  final dynamic deal;
  const _ReserveButton({required this.deal});

  @override
  State<_ReserveButton> createState() => _ReserveButtonState();
}

class _ReserveButtonState extends State<_ReserveButton> {
  bool _isReserving = false;

  void _reserveDeal() async {
    setState(() {
      _isReserving = true;
    });

    final reservationResponse = await ApiService.reserveDeal(
      dealId: widget.deal['id'],
      studentId: 1,
    );

    if (!mounted) return;

    setState(() {
      _isReserving = false;
    });

    if (reservationResponse != null && reservationResponse['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            deal: widget.deal,
            reservation: reservationResponse,
          ),
        ),
      );
    } else {
      final msg = reservationResponse != null
          ? reservationResponse['detail'] ?? reservationResponse['message']
          : "Failed to reserve this deal.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isReserving ? null : _reserveDeal,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006C5B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isReserving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Text(
              "Reserve Now",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}

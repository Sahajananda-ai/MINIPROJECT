import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'checkout.dart';

class StudentMapScreen extends StatefulWidget {
  const StudentMapScreen({super.key});

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  // Default campus fallback coordinates (Central Campus Hub)
  LatLng _currentLocation = const LatLng(28.6139, 77.2090);
  bool _hasRealLocation = false;
  
  List<dynamic> _deals = [];
  bool _isLoading = true;
  dynamic _selectedDeal;

  @override
  void initState() {
    super.initState();
    _initLocationAndDeals();
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
        _mapController.move(_currentLocation, 14.0);
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

  void _recenterToUser() {
    _mapController.move(_currentLocation, 14.5);
  }

  double _calculateDistanceKm(double lat, double lng) {
    const Distance distance = Distance();
    return double.parse(
      distance.as(LengthUnit.Kilometer, _currentLocation, LatLng(lat, lng)).toStringAsFixed(1),
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
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                if (_selectedDeal != null) {
                  setState(() {
                    _selectedDeal = null;
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
                    color: const Color(0xFF006C5B).withOpacity(0.08),
                    borderColor: const Color(0xFF006C5B).withOpacity(0.4),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // Markers Layer: Student Beacon + Vendor Deal Markers
              MarkerLayer(
                markers: [
                  // Student Current Location Beacon
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Mystery Box Vendor Markers
                  ..._deals.map((deal) {
                    final vendor = deal['vendor'] ?? {};
                    final double lat = (vendor['latitude'] as num?)?.toDouble() ?? 28.6139;
                    final double lng = (vendor['longitude'] as num?)?.toDouble() ?? 77.2090;
                    final String category = vendor['shop_category'] ?? 'Food';
                    final price = deal['start_price']?.toString() ?? '120';
                    final isSelected = _selectedDeal != null && _selectedDeal['id'] == deal['id'];

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 90,
                      height: 75,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDeal = deal;
                          });
                          _mapController.move(LatLng(lat, lng), 15.0);
                        },
                        child: Column(
                          children: [
                            // Custom Elevated Pin Badge
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : const Color(0xFF006C5B),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
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

          // Floating GPS / Recenter Button
          Positioned(
            right: 16,
            bottom: _selectedDeal != null ? 240 : 30,
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006C5B),
              onPressed: _recenterToUser,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Interactive Deal Bottom Preview Card
          if (_selectedDeal != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildDealPreviewCard(_selectedDeal),
            ),
        ],
      ),
    );
  }

  Widget _buildDealPreviewCard(dynamic deal) {
    final vendor = deal['vendor'] ?? {};
    final double lat = (vendor['latitude'] as num?)?.toDouble() ?? 28.6139;
    final double lng = (vendor['longitude'] as num?)?.toDouble() ?? 77.2090;
    final distance = _calculateDistanceKm(lat, lng);
    final originalPrice = deal['original_value']?.toString() ?? '400';
    final currentPrice = deal['start_price']?.toString() ?? '180';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
                          color: Colors.green.withOpacity(0.12),
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class StudentMapScreen extends StatefulWidget {
  const StudentMapScreen({super.key});

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  // A default starting location (e.g., center of New Delhi)
  final LatLng _initialCenter = const LatLng(28.6139, 77.2090);
  
  List<dynamic> _deals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeals();
  }

  Future<void> _fetchDeals() async {
    setState(() {
      _isLoading = true;
    });
    
    final deals = await ApiService.getActiveDeals();
    
    if (mounted) {
      setState(() {
        _deals = deals;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Mystery Boxes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              // This layer pulls the actual map images from OpenStreetMap for free!
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mystery_box_app',
              ),
              MarkerLayer(
                markers: _deals.map((deal) {
                  final vendor = deal['vendor'];
                  return Marker(
                    point: LatLng(vendor['latitude'], vendor['longitude']),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        _showDealDetails(context, deal);
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchDeals,
        icon: const Icon(Icons.refresh),
        label: const Text('Scan Area'),
      ),
    );
  }

  void _showDealDetails(BuildContext context, dynamic deal) {
    final vendor = deal['vendor'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor['name'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Category: ${vendor['shop_category']}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Original Price"),
                      Text(
                        "₹${deal['original_value']}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Current Price"),
                      Text(
                        "₹${deal['start_price']}", // In real app, this should calculate decay
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement Checkout logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Proceeding to checkout...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Reserve Now",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

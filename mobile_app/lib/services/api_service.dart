import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ApiService {
  // Since we are running locally, we point to the FastAPI localhost server.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Simulates a vendor registering or logging in to get their ID
  /// (In a real app, this would happen during a signup screen)
  static Future<int> getOrCreateTestVendor() async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendors/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": "The Great Indian Bakery",
        "email": "testbakery@gmail.com",
        "fssai_license": "FSSAI-12345678",
        "shop_category": "Bakery",
        "latitude": 28.6139,
        "longitude": 77.2090
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create vendor: ${response.body}');
    }
  }

  /// Sends the Deal Data to the FastAPI Python server
  static Future<bool> createMysteryBox({
    required int vendorId,
    required double originalValue,
    required double startPrice,
    required double minPrice,
    required int quantity,
    required DateTime closingTime,
    String? title,
    String? description,
    String? dietaryTag,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deals/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "vendor_id": vendorId,
        "title": title ?? "Surplus Mystery Box",
        "description": description,
        "dietary_tag": dietaryTag ?? "Vegetarian",
        "image_url": imageUrl,
        "original_value": originalValue,
        "start_price": startPrice,
        "min_price": minPrice,
        "quantity": quantity,
        "closing_time": closingTime.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("API Error: ${response.body}");
      return false;
    }
  }

  /// Fetches all active deals from the FastAPI backend
  static Future<List<dynamic>> getActiveDeals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/deals/active'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load deals');
    }
  }

  /// Reserves a deal for a student (5 minute lock)
  static Future<Map<String, dynamic>?> reserveDeal({
    required int dealId,
    required int studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "deal_id": dealId,
          "student_id": studentId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("Reserve error: $e");
      return null;
    }
  }

  /// Updates student's GPS location in PostGIS for spatial notifications
  static Future<bool> updateStudentLocation({
    required int studentId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$studentId/location?latitude=$latitude&longitude=$longitude'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Location update error: $e");
      return false;
    }
  }

  /// Creates a finalized order in the database, permanently deducting stock and generating a verified pickup pass
  static Future<Map<String, dynamic>?> createOrder({
    required int dealId,
    required int studentId,
    String paymentMethod = "UPI",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/orders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "deal_id": dealId,
          "student_id": studentId,
          "payment_method": paymentMethod,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Create order failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Create order error: $e");
    }
    return null;
  }

  /// Verifies a customer pickup code strictly against PostgreSQL database records
  static Future<Map<String, dynamic>> verifyPickupCode({
    required int vendorId,
    required String pickupCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/orders/verify-pickup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "vendor_id": vendorId,
          "pickup_code": pickupCode.trim().toUpperCase(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"], "order": data["order"]};
      } else {
        return {"success": false, "message": data["detail"] ?? "Invalid passcode"};
      }
    } catch (e) {
      debugPrint("Verify code error: $e");
      return {"success": false, "message": "Backend unreachable or connection error"};
    }
  }

  /// Fetches real walking street route coordinates from the free public OSRM Walking API
  static Future<Map<String, dynamic>?> fetchWalkingRoute({
    required double startLng,
    required double startLat,
    required double endLng,
    required double endLat,
  }) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/walking/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson&steps=true';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coords = (route['geometry']['coordinates'] as List)
              .map((c) => [ (c[0] as num).toDouble(), (c[1] as num).toDouble() ])
              .toList();
          final distance = (route['distance'] as num).toDouble();
          final durationSec = (route['duration'] as num).toDouble();
          return {
            'coordinates': coords,
            'distanceMeters': distance.round(),
            'durationMinutes': (durationSec / 60).round().clamp(1, 999),
          };
        }
      }
    } catch (e) {
      debugPrint("OSRM walking route error: $e");
    }
    return null;
  }

  /// Completes / redeems a reserved deal at pickup
  static Future<bool> completeDeal({
    required int dealId,
    required int studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/$dealId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"student_id": studentId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Complete deal error: $e");
      return false;
    }
  }

  /// Asks SaveBite AI for personalized surplus recommendations
  static Future<Map<String, dynamic>?> getAiRecommendation({
    String query = "best value",
    double? maxBudget,
    String? category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "query": query,
          "max_budget": maxBudget,
          "preferred_category": category,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("AI recommendation error: $e");
    }
    return null;
  }

  /// Curates an enticing mystery description from surplus food photos/items without revealing contents
  static Future<Map<String, dynamic>?> generateMysteryBoxDescription({
    String? category,
    String? itemsText,
    List<String>? itemsDetected,
    String? imageBase64,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/generate-box-description'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "category": category ?? "Bakery",
          "items_text": itemsText,
          "items_detected": itemsDetected,
          "image_base64": imageBase64,
          "image_url": imageUrl,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("AI Vision error: ${response.body}");
      }
    } catch (e) {
      print("AI Vision request failed: $e");
    }
    return null;
  }
}


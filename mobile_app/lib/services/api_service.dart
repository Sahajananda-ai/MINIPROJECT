import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'session_service.dart';

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

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = SessionService().token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Reads the server's error message from a failed response, falling back to
  /// the status code so the UI never shows a blank error.
  static String _errorOf(http.Response response, {String fallback = 'Request failed'}) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is List) {
          // Pydantic validation errors
          return detail
              .map((e) => '${e['msg'] ?? 'invalid input'}${e['loc'] != null ? ' (${e['loc'].skip(1).join('.')})' : ''}')
              .join('; ');
        }
        return detail.toString();
      }
    } catch (_) {}
    return fallback;
  }

  // ───────────────────────── AUTHENTICATION ─────────────────────────

  static Future<Map<String, dynamic>?> registerStudent({
    required String name,
    required String email,
    required String password,
  }) async {
    return _authCall('/auth/register/student', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>?> registerVendor({
    required String name,
    required String email,
    required String password,
    required String fssaiLicense,
    required String shopCategory,
    required double latitude,
    required double longitude,
  }) async {
    return _authCall('/auth/register/vendor', {
      'name': name,
      'email': email,
      'password': password,
      'fssai_license': fssaiLicense,
      'shop_category': shopCategory,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return _authCall('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>?> _authCall(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        SessionService().setSession(
          token: data['access_token'] as String,
          role: data['role'] as String,
          id: (data['id'] as num).toInt(),
          name: data['name'] as String?,
          email: data['email'] as String?,
        );
        return data;
      }
      return {'error': _errorOf(response, fallback: 'Sign in failed')};
    } catch (e) {
      debugPrint('Auth error: $e');
      return {'error': 'Backend unreachable. Please check your connection.'};
    }
  }

  /// Returns the signed-in user as the server sees them (validates the token).
  static Future<Map<String, dynamic>?> me() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers(json: false),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('me() error: $e');
    }
    return null;
  }

  static Future<void> signOut() => SessionService().clear();

  // ───────────────────────── VENDOR / DEALS ─────────────────────────

  /// Sends the Deal Data to the FastAPI Python server.
  /// The vendor identity comes from the session token, not from a parameter.
  static Future<bool> createMysteryBox({
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
      headers: _headers(),
      body: jsonEncode({
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
      debugPrint("Create deal error: ${_errorOf(response)}");
      return false;
    }
  }

  /// Fetches all active deals, including the LIVE decayed `current_price`.
  static Future<List<dynamic>> getActiveDeals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/deals/active'),
      headers: _headers(json: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load deals');
    }
  }

  /// Reserves a deal for the signed-in student (5 minute lock).
  static Future<Map<String, dynamic>?> reserveDeal({
    required int dealId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/deals/reserve'),
            headers: _headers(),
            body: jsonEncode({"deal_id": dealId}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return data;
      return {'detail': data['detail'] ?? 'Reservation failed'};
    } catch (e) {
      debugPrint("Reserve error: $e");
      return null;
    }
  }

  /// Updates the signed-in student's GPS location in PostGIS.
  static Future<bool> updateStudentLocation({
    required int studentId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$studentId/location?latitude=$latitude&longitude=$longitude'),
        headers: _headers(json: false),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Location update error: $e");
      return false;
    }
  }

  /// Creates a finalized order in the database, permanently deducting stock and
  /// generating a verified pickup pass code.
  ///
  /// [clientRequestId] makes retries safe: the same key returns the same order.
  static Future<Map<String, dynamic>?> createOrder({
    required int dealId,
    required String clientRequestId,
    String paymentMethod = "UPI",
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/deals/orders/create'),
            headers: _headers(),
            body: jsonEncode({
              "deal_id": dealId,
              "payment_method": paymentMethod,
              "client_request_id": clientRequestId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return data;
      return {'detail': data['detail'] ?? 'Order failed'};
    } catch (e) {
      debugPrint("Create order error: $e");
      return null;
    }
  }

  /// Fetches the signed-in student's real orders from the server.
  static Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/deals/orders/me'),
            headers: _headers(json: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      debugPrint("getMyOrders HTTP ${response.statusCode}");
    } catch (e) {
      debugPrint("getMyOrders error: $e");
    }
    return [];
  }

  /// Fetches live orders for the signed-in vendor's store.
  static Future<List<dynamic>> getMyVendorOrders() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/deals/orders/vendor/me'),
            headers: _headers(json: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      debugPrint("getMyVendorOrders HTTP ${response.statusCode}");
    } catch (e) {
      debugPrint("getMyVendorOrders error: $e");
    }
    return [];
  }

  /// Verifies a customer pickup code. The redeeming store is taken from the
  /// vendor's token server-side, so only the right store can redeem a code.
  static Future<Map<String, dynamic>> verifyPickupCode({
    required String pickupCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/deals/orders/verify-pickup'),
            headers: _headers(),
            body: jsonEncode({"pickup_code": pickupCode.trim().toUpperCase()}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"],
          "order": data["order"]
        };
      }
      return {
        "success": false,
        "message": data["detail"] ?? "Invalid passcode",
        "status": response.statusCode,
      };
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

  /// Asks SaveBite AI for personalized surplus recommendations
  static Future<Map<String, dynamic>?> getAiRecommendation({
    String query = "best value",
    double? maxBudget,
    String? category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/recommend'),
        headers: _headers(),
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
      debugPrint("AI recommendation error: $e");
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
        headers: _headers(),
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
        debugPrint("AI Vision error: ${response.body}");
      }
    } catch (e) {
      debugPrint("AI Vision request failed: $e");
    }
    return null;
  }
}

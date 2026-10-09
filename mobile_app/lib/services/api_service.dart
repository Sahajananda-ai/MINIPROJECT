import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deals/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "vendor_id": vendorId,
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
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost, or localhost for web/iOS simulator
  // Since we don't know the exact environment, assuming a generic localhost/10.0.2.2 fallback
  // For a real app, this should be configurable or use an env variable.
  static const String baseUrl = 'http://127.0.0.1:8000'; // Default to localhost

  // A helper method to get the correct URL based on the platform, if needed,
  // but for simplicity, we'll assume the API is available at baseUrl.

  static Future<bool> createMysteryBox({
    required int vendorId,
    required double originalValue,
    required double startPrice,
    required double minPrice,
    required int quantity,
    required DateTime closingTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vendor_id': vendorId,
          'original_value': originalValue,
          'start_price': startPrice,
          'min_price': minPrice,
          'quantity': quantity,
          'closing_time': closingTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create deal: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during createMysteryBox: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getActiveDeals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/deals/active'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get active deals: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception during getActiveDeals: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> reserveDeal({
    required int dealId,
    required int studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deals/reserve'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deal_id': dealId,
          'student_id': studentId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to reserve deal: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during reserveDeal: $e');
      return null;
    }
  }
}

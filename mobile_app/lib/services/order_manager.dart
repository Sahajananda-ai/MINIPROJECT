import 'package:flutter/foundation.dart';

class MysteryBoxOrder {
  final int dealId;
  final int studentId;
  final String vendorName;
  final String shopCategory;
  final double paidPrice;
  final double originalValue;
  final String pickupCode;
  final DateTime reservedAt;
  final DateTime closingTime;
  final double latitude;
  final double longitude;
  bool isCollected;

  MysteryBoxOrder({
    required this.dealId,
    required this.studentId,
    required this.vendorName,
    required this.shopCategory,
    required this.paidPrice,
    required this.originalValue,
    required this.pickupCode,
    required this.reservedAt,
    required this.closingTime,
    this.latitude = 28.6139,
    this.longitude = 77.2090,
    this.isCollected = false,
  });
}

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<MysteryBoxOrder> _orders = [
    // Pre-populate with a completed demo meal rescue for judge presentation
    MysteryBoxOrder(
      dealId: 999,
      studentId: 1,
      vendorName: "Campus Green Cafe",
      shopCategory: "Cafe",
      paidPrice: 120.0,
      originalValue: 350.0,
      pickupCode: "RESCUE-9281",
      reservedAt: DateTime.now().subtract(const Duration(days: 1)),
      closingTime: DateTime.now().subtract(const Duration(hours: 20)),
      latitude: 28.6150,
      longitude: 77.2110,
      isCollected: true,
    ),
  ];

  List<MysteryBoxOrder> get orders => List.unmodifiable(_orders);

  List<MysteryBoxOrder> get activeOrders =>
      _orders.where((o) => !o.isCollected).toList();

  List<MysteryBoxOrder> get completedOrders =>
      _orders.where((o) => o.isCollected).toList();

  /// Returns true if the student already has an active (uncollected) order for this deal.
  /// Prevents duplicate reservations on the frontend side.
  bool hasActiveOrderForDeal(int dealId) {
    return _orders.any((o) => o.dealId == dealId && !o.isCollected);
  }

  double get totalSavings => _orders.fold(
      0.0, (sum, o) => sum + (o.originalValue - o.paidPrice));

  int get totalMealsRescued => _orders.length;

  double get totalCo2AvoidedKg =>
      double.parse((totalSavings * 0.015 + (totalMealsRescued * 2.1)).toStringAsFixed(1));

  void addOrder({
    required int dealId,
    required int studentId,
    required String vendorName,
    required String shopCategory,
    required double paidPrice,
    required double originalValue,
    required DateTime closingTime,
    double? latitude,
    double? longitude,
    String? pickupCode,
  }) {
    final code = (pickupCode != null && pickupCode.isNotEmpty)
        ? pickupCode
        : "MB-$dealId-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}";
    final order = MysteryBoxOrder(
      dealId: dealId,
      studentId: studentId,
      vendorName: vendorName,
      shopCategory: shopCategory,
      paidPrice: paidPrice,
      originalValue: originalValue,
      pickupCode: code,
      reservedAt: DateTime.now(),
      closingTime: closingTime,
      latitude: latitude ?? 28.6139,
      longitude: longitude ?? 77.2090,
      isCollected: false,
    );
    _orders.insert(0, order);
    notifyListeners();
  }

  /// Finds an order by full code (e.g. MB-41-2891), deal ID, or short PIN
  MysteryBoxOrder? findOrderByCodeOrId(String input) {
    final trimmed = input.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    for (var o in _orders) {
      if (o.pickupCode.toUpperCase() == trimmed) return o;
      if (o.dealId.toString() == trimmed) return o;
      if (trimmed.contains(o.dealId.toString())) return o;
    }
    return null;
  }

  bool markOrderCollectedByCode(String codeOrId) {
    final order = findOrderByCodeOrId(codeOrId);
    if (order != null) {
      order.isCollected = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void markOrderCollected(int dealId) {
    for (var o in _orders) {
      if (o.dealId == dealId) {
        o.isCollected = true;
        break;
      }
    }
    notifyListeners();
  }
}

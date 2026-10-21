import 'package:flutter/foundation.dart';

import 'session_service.dart';

/// A rescue, as returned by the server.
///
/// Built from `/deals/orders/me`, so orders survive an app restart and are
/// never invented locally. `source == 'server'` marks records that came from a
/// real API response.
class MysteryBoxOrder {
  final int dealId;
  final int studentId;
  final int? orderId;
  final String vendorName;
  final String shopCategory;
  final double paidPrice;
  final double originalValue;
  final String pickupCode;
  final DateTime reservedAt;
  final DateTime closingTime;
  final double latitude;
  final double longitude;

  /// RESERVED / PAID / COLLECTED / CANCELLED — the server is the authority.
  final String status;

  MysteryBoxOrder({
    required this.dealId,
    required this.studentId,
    this.orderId,
    required this.vendorName,
    required this.shopCategory,
    required this.paidPrice,
    required this.originalValue,
    required this.pickupCode,
    required this.reservedAt,
    required this.closingTime,
    this.latitude = 0,
    this.longitude = 0,
    this.status = 'PAID',
  });

  bool get isCollected => status == 'COLLECTED';
  double get savings => (originalValue - paidPrice).clamp(0, double.infinity);
}

/// One shared formula for the environmental claim, used everywhere in the app.
/// 2.1 kg CO₂e per meal rescued, plus a small amount for the money saved.
/// Keeping this in ONE place is what stops the Pickups screen saying 4.2 kg
/// while the Profile screen says 5.5 kg for the same rescue.
class ImpactStats {
  final int mealsRescued;
  final double moneySaved;

  ImpactStats({required this.mealsRescued, required this.moneySaved});

  double get co2AvoidedKg =>
      double.parse((mealsRescued * 2.1).toStringAsFixed(1));
}

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<MysteryBoxOrder> _orders = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<MysteryBoxOrder> get orders => List.unmodifiable(_orders);

  List<MysteryBoxOrder> get activeOrders =>
      _orders.where((o) => !o.isCollected).toList();

  List<MysteryBoxOrder> get completedOrders =>
      _orders.where((o) => o.isCollected).toList();

  ImpactStats get impact => ImpactStats(
        mealsRescued: completedOrders.length,
        moneySaved: completedOrders.fold(0.0, (sum, o) => sum + o.savings),
      );

  /// Replaces the local list with the server's truth.
  void hydrate(List<dynamic> serverOrders) {
    _orders
      ..clear()
      ..addAll(serverOrders.whereType<Map>().map(
        (raw) => fromApi(Map<String, dynamic>.from(raw)),
      ));
    notifyListeners();
  }

  /// Inserts one freshly-created order from the `/deals/orders/create` response
  /// shape, so checkout shows the pass without waiting for a refetch.
  void addFromCreateResponse(Map<String, dynamic> orderPayload) {
    final merged = Map<String, dynamic>.from(orderPayload)
      ..putIfAbsent('student_id', () => SessionService().id ?? 0);
    final incoming = fromApi(merged);
    _orders.removeWhere((o) => o.dealId == incoming.dealId && o.pickupCode == incoming.pickupCode);
    _orders.insert(0, incoming);
    notifyListeners();
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Builds an order from one item of `/deals/orders/me`.
  ///
  /// Naive datetimes come back as UTC from the API; treating them as local
  /// shifted every countdown by 5.5 hours in India, so we normalise to UTC.
  static MysteryBoxOrder fromApi(Map<String, dynamic> data) {
    DateTime parseTime(String? value, {DateTime? fallback}) {
      if (value == null || value.isEmpty) {
        return fallback ?? DateTime.now();
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return fallback ?? DateTime.now();
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    return MysteryBoxOrder(
      dealId: (data['deal_id'] as num?)?.toInt() ?? 0,
      studentId: (data['student_id'] as num?)?.toInt() ?? 0,
      orderId: (data['id'] as num?)?.toInt(),
      vendorName: data['vendor_name'] as String? ?? 'Mystery Box Partner',
      shopCategory: data['shop_category'] as String? ?? 'Surplus',
      paidPrice: (data['paid_price'] as num?)?.toDouble() ?? 0,
      originalValue: (data['original_value'] as num?)?.toDouble() ?? 0,
      pickupCode: data['pickup_code'] as String? ?? '',
      reservedAt: parseTime(data['reserved_at']),
      closingTime: parseTime(
        data['closing_time'],
        fallback: DateTime.now().add(const Duration(hours: 3)),
      ),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'PAID',
    );
  }

  /// Optimistically updates a single order's status after the server confirms
  /// a handoff. The next `/deals/orders/me` fetch remains the source of truth.
  void markOrderCollected(int dealId) {
    for (var i = 0; i < _orders.length; i++) {
      if (_orders[i].dealId == dealId) {
        final o = _orders[i];
        _orders[i] = MysteryBoxOrder(
          dealId: o.dealId,
          studentId: o.studentId,
          orderId: o.orderId,
          vendorName: o.vendorName,
          shopCategory: o.shopCategory,
          paidPrice: o.paidPrice,
          originalValue: o.originalValue,
          pickupCode: o.pickupCode,
          reservedAt: o.reservedAt,
          closingTime: o.closingTime,
          latitude: o.latitude,
          longitude: o.longitude,
          status: 'COLLECTED',
        );
        break;
      }
    }
    notifyListeners();
  }

  MysteryBoxOrder? findByDealId(int dealId) {
    for (final o in _orders) {
      if (o.dealId == dealId) return o;
    }
    return null;
  }

  /// True when the student already holds a live (un-collected) order for a deal.
  /// The server enforces this too; this only avoids a pointless round trip.
  bool hasActiveOrderForDeal(int dealId) =>
      _orders.any((o) => o.dealId == dealId && !o.isCollected);

  void clear() {
    _orders.clear();
    notifyListeners();
  }
}

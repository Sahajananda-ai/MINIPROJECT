/// Helpers for reading the price fields of a deal payload from `/deals/active`.
///
/// The server computes a live, time-decayed `current_price` on every response.
/// The UI must render that value — showing `start_price` while charging the
/// decayed price made the app's headline feature ("prices drop every minute")
/// invisible to users and inconsistent between screens.
library;

/// The price the student will actually pay right now.
double livePriceOf(dynamic deal, {double fallback = 0}) {
  if (deal is Map) {
    final current = deal['current_price'];
    if (current is num) return current.toDouble();
    final start = deal['start_price'];
    if (start is num) return start.toDouble();
  }
  return fallback;
}

/// The money a student saves compared with the shop's normal value.
double savingsOf(dynamic deal) {
  if (deal is Map) {
    final original = (deal['original_value'] as num?)?.toDouble();
    if (original == null) return 0;
    return (original - livePriceOf(deal)).clamp(0, double.infinity);
  }
  return 0;
}

/// Discount against the original value, rounded. Server-provided when present
/// so the number never disagrees with the one on the checkout screen.
int discountPercentOf(dynamic deal) {
  if (deal is Map) {
    final server = deal['discount_percent'];
    if (server is num) return server.toInt();
    final original = (deal['original_value'] as num?)?.toDouble();
    if (original == null || original <= 0) return 0;
    return (((original - livePriceOf(deal)) / original) * 100).round().clamp(0, 99);
  }
  return 0;
}

/// Formats a rupee amount without trailing decimals (₹210, ₹149).
String rupees(dynamic amount) {
  final value = (amount as num?)?.toDouble() ?? 0;
  return value == value.roundToDouble()
      ? '₹${value.toInt()}'
      : '₹${value.toStringAsFixed(0)}';
}

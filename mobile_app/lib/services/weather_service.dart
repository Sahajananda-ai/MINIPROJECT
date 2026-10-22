import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live weather for a pickup point, fetched from the free Open-Meteo API
/// (no API key required — listed in the public-apis collection).
class PickupWeather {
  final double temperatureC;
  final double precipitationMm;

  /// True when it is raining now or the next two hours are likely to rain
  /// (hourly precipitation probability >= 60%).
  final bool rainLikely;

  const PickupWeather({
    required this.temperatureC,
    required this.precipitationMm,
    required this.rainLikely,
  });

  bool get isRaining => precipitationMm >= 0.1;

  /// One-line nudge shown on pickup cards; [closingText] is the human
  /// pickup deadline so the advice is actionable, not just a temperature.
  String nudge(String closingText) {
    if (isRaining) {
      return "Rain now \u2014 collect by $closingText";
    }
    if (rainLikely) {
      return "Rain expected soon \u2014 collect by $closingText";
    }
    final t = temperatureC.round();
    return "$t\u00b0C \u2022 Dry \u2014 good walking weather for pickup";
  }
}

/// Fetches and caches per-location weather. The cache respects the free
/// tier's fairness policy and avoids refetching on every rebuild.
class WeatherService {
  WeatherService._();

  static final Map<String, PickupWeather> _cache = {};

  static String _key(double lat, double lng) =>
      "${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}";

  /// Returns null on any failure — weather is an enhancement and must
  /// never block the pickup flow.
  static Future<PickupWeather?> getPickupWeather(
    double latitude,
    double longitude,
  ) async {
    final key = _key(latitude, longitude);
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=${latitude.toStringAsFixed(4)}"
        "&longitude=${longitude.toStringAsFixed(4)}"
        "&current=temperature_2m,precipitation"
        "&hourly=precipitation_probability"
        "&forecast_days=1&timezone=auto",
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      final hourly = data['hourly'] as Map<String, dynamic>?;
      if (current == null || hourly == null) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
      final precip = (current['precipitation'] as num?)?.toDouble() ?? 0;

      // Rain-likely: currently wet, or >=60% chance within the next 2 hours.
      bool rainLikely = precip >= 0.1;
      final times = (hourly['time'] as List? ?? []).cast<String>();
      final probs = (hourly['precipitation_probability'] as List? ?? []);
      final nowIso = (current['time'] as String?) ?? '';
      if (!rainLikely && times.isNotEmpty) {
        var idx = times.indexWhere((t) => t.compareTo(nowIso) >= 0);
        if (idx < 0) idx = times.length - 1;
        for (var h = idx; h < idx + 2 && h < probs.length; h++) {
          final p = (probs[h] as num?)?.toInt() ?? 0;
          if (p >= 60) {
            rainLikely = true;
            break;
          }
        }
      }

      final weather = PickupWeather(
        temperatureC: temp,
        precipitationMm: precip,
        rainLikely: rainLikely,
      );
      _cache[key] = weather;
      return weather;
    } catch (_) {
      return null;
    }
  }
}

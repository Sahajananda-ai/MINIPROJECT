import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the signed-in user's identity and bearer token.
///
/// Every API call that used to hardcode `student_id: 1` / `vendor_id: 1` now
/// reads from here, and the server re-derives identity from the token anyway —
/// so a tampered client value cannot act as someone else.
class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const _storageKey = 'savebite.session.v1';

  String? _token;
  String? _name;
  String? _email;
  String? _role;
  int? _id;
  bool _loaded = false;

  String? get token => _token;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  int? get id => _id;
  bool get isAuthenticated => _token != null && _role != null;
  bool get isStudent => _role == 'student';
  bool get isVendor => _role == 'vendor';
  bool get isLoaded => _loaded;

  /// Restores a previous session. Fails silently to a signed-out state.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _name = data['name'] as String?;
        _email = data['email'] as String?;
        _role = data['role'] as String?;
        _id = (data['id'] as num?)?.toInt();
      }
    } catch (_) {
      // Corrupt/absent storage: start signed out rather than crash.
      _token = null;
      _role = null;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token == null) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(
          _storageKey,
          jsonEncode({
            'token': _token,
            'name': _name,
            'email': _email,
            'role': _role,
            'id': _id,
          }),
        );
      }
    } catch (_) {
      // Persistence is best-effort; the in-memory session still works.
    }
  }

  void setSession({
    required String token,
    required String role,
    required int id,
    String? name,
    String? email,
  }) {
    _token = token;
    _role = role;
    _id = id;
    _name = name;
    _email = email;
    notifyListeners();
    _persist();
  }

  Future<void> clear() async {
    _token = null;
    _role = null;
    _id = null;
    _name = null;
    _email = null;
    notifyListeners();
    await _persist();
  }
}

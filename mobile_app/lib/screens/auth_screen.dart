import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import 'student_shell.dart';
import 'vendor_dashboard.dart';

/// Real authentication for SaveBite: students and vendors sign in or create an
/// account. Identity now comes from a server-issued bearer token, so no screen
/// has to invent a `student_id` / `vendor_id` any more.
class AuthScreen extends StatefulWidget {
  final String role; // 'student' | 'vendor'

  const AuthScreen({super.key, this.role = 'student'});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // SaveBite matte palette
  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _tealPrimary = Color(0xFF006C5B);
  static const Color _warmAmber = Color(0xFFFF8C42);
  static const Color _charcoal = Color(0xFF2D2D2D);

  late String _role = widget.role;
  bool _isRegister = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fssaiCtrl = TextEditingController();
  String _shopCategory = 'Bakery';

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  final List<String> _categories = const [
    'Bakery',
    'Cafe',
    'Meals',
    'Groceries',
    'Restaurant',
    'Juice & Snacks',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fssaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    Map<String, dynamic>? result;
    if (_isRegister) {
      if (_role == 'vendor') {
        // Vendors publish at a real campus point; geo-lookup comes next sprint.
        result = await ApiService.registerVendor(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fssaiLicense: _fssaiCtrl.text.trim(),
          shopCategory: _shopCategory,
          latitude: 28.6139,
          longitude: 77.2090,
        );
      } else {
        result = await ApiService.registerStudent(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
    } else {
      result = await ApiService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
      );
    }

    if (!mounted) return;

    if (result == null || result['error'] != null || result['access_token'] == null) {
      setState(() {
        _busy = false;
        _error = (result?['error'] ?? 'Could not sign you in. Please try again.')
            .toString();
      });
      return;
    }

    final session = SessionService();
    setState(() => _busy = false);

    // Route into the right experience for this account type.
    if (session.isVendor) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentShell()),
        (route) => false,
      );
    }
  }

  void _switchMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = _role == 'vendor';

    return Scaffold(
      backgroundColor: _cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Brand mark ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _tealPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SaveBite',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _charcoal,
                          ),
                        ),
                        Text(
                          isVendor ? 'Vendor portal' : 'Rescue surplus food',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  _isRegister
                      ? (isVendor ? 'Open your shop to rescues' : 'Start rescuing food')
                      : 'Welcome back',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _charcoal,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegister
                      ? (isVendor
                          ? 'List surplus in under a minute and sell what would be wasted.'
                          : 'Create an account to reserve mystery boxes near campus.')
                      : (isVendor
                          ? 'Sign in to manage your surplus listings and pickups.'
                          : 'Sign in to see live deals and your pickup passes.'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Role switch ──
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _tealPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _roleChip('I’m a student', !isVendor, () {
                        setState(() => _role = 'student');
                      }),
                      _roleChip('I’m a vendor', isVendor, () {
                        setState(() => _role = 'vendor');
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isRegister && _role == 'student') ...[
                  _label('Full name'),
                  _field(
                    controller: _nameCtrl,
                    hint: 'Rahul Sharma',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                  ),
                ],

                if (_isRegister && isVendor) ...[
                  _label('Shop name'),
                  _field(
                    controller: _nameCtrl,
                    hint: 'Gupta Sweets & Bakery',
                    icon: Icons.storefront_outlined,
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Enter your shop name' : null,
                  ),
                ],

                _label('Email'),
                _field(
                  controller: _emailCtrl,
                  hint: 'you@campus.edu',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Password'),
                _field(
                  controller: _passwordCtrl,
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.black45,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Use at least 6 characters' : null,
                ),

                if (_isRegister && isVendor) ...[
                  const SizedBox(height: 16),
                  _label('FSSAI licence number'),
                  _field(
                    controller: _fssaiCtrl,
                    hint: '11519024000111',
                    icon: Icons.verified_outlined,
                    validator: (v) =>
                        (v == null || v.trim().length < 6) ? 'Enter a valid FSSAI number' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Shop category'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4C9B8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _shopCategory,
                        isExpanded: true,
                        style: GoogleFonts.inter(fontSize: 14, color: _charcoal),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _shopCategory = v ?? _shopCategory),
                      ),
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3B4B4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFD94040), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFFD94040)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Primary action ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tealPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _tealPrimary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            _isRegister ? 'Create account' : 'Sign in',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _switchMode,
                    child: Text(
                      _isRegister
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _tealPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _warmAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVendor
                          ? '🔒 FSSAI-verified shops only'
                          : '🌱 Campus email recommended',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB85C10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: _charcoal),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.black45),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD4C9B8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD4C9B8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _tealPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD94040)),
        ),
      ),
    );
  }

  Widget _roleChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _tealPrimary : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }
}

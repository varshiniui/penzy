import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// ─────────────────────────────────────────────
// PENZY DESIGN TOKENS
// ─────────────────────────────────────────────
class P {
  static const Color cream     = Color(0xFFFDF8F2);
  static const Color creamDark = Color(0xFFF5EDE0);
  static const Color sage      = Color(0xFF8BAF8B);
  static const Color sageDark  = Color(0xFF5E7D5E);
  static const Color rose      = Color(0xFFD4836A);
  static const Color blush     = Color(0xFFEBB8A4);
  static const Color navy      = Color(0xFF1F2D3D);
  static const Color amber     = Color(0xFFF6B554);
  static const Color lavender  = Color(0xFFB8A9D4);
  static const Color white     = Color(0xFFFEFCF8);
  static const Color textDark  = Color(0xFF2C1A0E);
  static const Color textMid   = Color(0xFF7A6652);
  static const Color textLight = Color(0xFFB8A898);
  static const Color border    = Color(0xFFEDE0D0);
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(seedColor: P.sage),
        scaffoldBackgroundColor: P.cream,
        // ── Ensure Material Icons font loads on web ──
        iconTheme: const IconThemeData(color: P.textDark),
      ),
      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────
// TOP TOAST  (slides in from top-center)
// ─────────────────────────────────────────────
class PenzyToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext ctx, {
    required String message,
    IconData icon = Icons.check_circle_outline,
    Color color = P.sage,
    Duration duration = const Duration(seconds: 2),
  }) {
    _entry?.remove();
    _entry = null;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _Toast(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
        onDone: () { if (_entry == e) { _entry?.remove(); _entry = null; } },
      ),
    );
    _entry = e;
    Overlay.of(ctx).insert(e);
  }
}

class _Toast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDone;
  const _Toast({required this.message, required this.icon, required this.color,
    required this.duration, required this.onDone});
  @override State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (mounted) { await _ctrl.reverse(); widget.onDone(); }
    });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 14,
      left: 24, right: 24,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: P.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.color.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 5)),
                  BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(widget.icon, color: widget.color, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.message,
                    style: const TextStyle(color: P.textDark, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AUTH GATE
// ─────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);
  @override State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  String? _user;
  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      return ProductPage(username: _user!, onLogout: () => setState(() => _user = null));
    }
    return AuthScreen(onLogin: (u) => setState(() => _user = u));
  }
}

// ─────────────────────────────────────────────
// USER STORE
// ─────────────────────────────────────────────
class UserStore {
  static final Map<String, String> _db = {'demo': 'demo123', 'admin': 'admin123'};
  static bool login(String u, String p) => _db[u] == p;
  static bool register(String u, String p) {
    if (_db.containsKey(u)) return false;
    _db[u] = p; return true;
  }
  static bool exists(String u) => _db.containsKey(u);
}

// ─────────────────────────────────────────────
// AUTH SCREEN
// ─────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  final void Function(String) onLogin;
  const AuthScreen({Key? key, required this.onLogin}) : super(key: key);
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _uCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  bool _obscP = true, _obscC = true, _loading = false;
  String? _err;

  late AnimationController _ani;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ani = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _ani, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ani, curve: Curves.easeOut));
    _ani.forward();
  }

  @override void dispose() { _ani.dispose(); _uCtrl.dispose(); _pCtrl.dispose(); _cCtrl.dispose(); super.dispose(); }

  void _switch() { setState(() { _isLogin = !_isLogin; _err = null; _pCtrl.clear(); _cCtrl.clear(); }); _ani.forward(from: 0); }

  void _submit() async {
    final u = _uCtrl.text.trim(), p = _pCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) { setState(() => _err = 'Please fill in all fields.'); return; }
    if (u.length < 3)           { setState(() => _err = 'Username needs 3+ characters.'); return; }
    if (p.length < 6)           { setState(() => _err = 'Password needs 6+ characters.'); return; }
    if (!_isLogin && _cCtrl.text.trim() != p) { setState(() => _err = 'Passwords do not match.'); return; }
    setState(() { _loading = true; _err = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isLogin) {
      if (UserStore.login(u, p)) { widget.onLogin(u); }
      else setState(() { _loading = false; _err = UserStore.exists(u) ? 'Wrong password.' : 'No account found.'; });
    } else {
      if (UserStore.register(u, p)) { widget.onLogin(u); }
      else setState(() { _loading = false; _err = 'Username taken.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: P.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // ── Branding ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
                    decoration: BoxDecoration(
                      color: P.navy,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: P.navy.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: Column(children: [
                      const Icon(Icons.edit_note_rounded, color: P.amber, size: 42),
                      const SizedBox(height: 10),
                      const Text('penzy', style: TextStyle(color: Colors.white, fontSize: 38,
                          fontWeight: FontWeight.w900, fontFamily: 'Georgia', letterSpacing: -1)),
                      const SizedBox(height: 5),
                      Text('your cozy stationery corner', style: TextStyle(
                          color: P.blush, fontSize: 13, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _dot(P.sage), _dot(P.blush), _dot(P.amber), _dot(P.lavender),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 18),

                  // ── Card ──
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: P.white, borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: P.border),
                      boxShadow: [BoxShadow(color: P.rose.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      // tabs
                      Container(
                        decoration: BoxDecoration(color: P.creamDark, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(4),
                        child: Row(children: [
                          _tab('Login', _isLogin, () { if (!_isLogin) _switch(); }),
                          _tab('Sign Up', !_isLogin, () { if (_isLogin) _switch(); }),
                        ]),
                      ),
                      const SizedBox(height: 22),
                      _field(_uCtrl, 'Username', Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_pCtrl, 'Password', Icons.lock_outline, obscure: _obscP,
                          toggle: () => setState(() => _obscP = !_obscP)),
                      if (!_isLogin) ...[
                        const SizedBox(height: 12),
                        _field(_cCtrl, 'Confirm Password', Icons.lock_outline, obscure: _obscC,
                            toggle: () => setState(() => _obscC = !_obscC)),
                      ],
                      if (_err != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: P.rose.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: P.rose.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: P.rose, size: 15),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_err!, style: const TextStyle(color: P.rose, fontSize: 12))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: P.sage, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(_isLogin ? 'Login' : 'Create Account',
                                  style: const TextStyle(color: Colors.white, fontSize: 15,
                                      fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_isLogin ? "New to penzy?  " : 'Already a fan?  ',
                        style: const TextStyle(color: P.textLight, fontSize: 13)),
                    GestureDetector(
                      onTap: _switch,
                      child: Text(_isLogin ? 'Sign Up' : 'Login',
                          style: const TextStyle(color: P.sageDark, fontSize: 13,
                              fontWeight: FontWeight.w700, decoration: TextDecoration.underline,
                              decorationColor: P.sageDark)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text('demo / demo123', style: TextStyle(color: P.textLight, fontSize: 11)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), width: 7, height: 7,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _tab(String label, bool active, VoidCallback tap) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? P.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
            color: active ? Colors.white : P.textLight,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14, fontFamily: 'Georgia')),
      ),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, VoidCallback? toggle}) {
    return Container(
      decoration: BoxDecoration(color: P.cream, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: P.border)),
      child: TextField(
        controller: ctrl, obscureText: obscure,
        style: const TextStyle(color: P.textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: P.textLight, fontSize: 14),
          prefixIcon: Icon(icon, color: P.textLight, size: 20),
          suffixIcon: toggle != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: P.textLight, size: 20),
                  onPressed: toggle)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CART ITEM
// ─────────────────────────────────────────────
class CartItem {
  final Map product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get unitPrice => double.tryParse(product["price"].toString()) ?? 0.0;
  double get subtotal => unitPrice * quantity;
  String get name => product["name"].toString();
  String get id => product["id"].toString();
}

// ─────────────────────────────────────────────
// LOCATION SERVICE
// ─────────────────────────────────────────────
class LocationService {
  Future<Map<String, dynamic>> get() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return {'ok': false, 'err': 'GPS is off. Enable Location Services.'};
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied)
          return {'ok': false, 'err': 'Location permission denied.'};
      }
      if (perm == LocationPermission.deniedForever)
        return {'ok': false, 'err': 'Location denied permanently. Check App Settings.'};
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final addr = await _toAddress(pos.latitude, pos.longitude);
      return {'ok': true, 'lat': pos.latitude, 'lng': pos.longitude, 'addr': addr, 'acc': pos.accuracy};
    } catch (e) {
      return {'ok': false, 'err': 'Error: $e'};
    }
  }

  Future<String> _toAddress(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return 'Address not found';
      final p = marks.first;
      return [p.street, p.subLocality, p.locality, p.administrativeArea, p.postalCode, p.country]
          .where((s) => s != null && s.isNotEmpty).join(', ');
    } catch (_) { return 'Could not resolve address'; }
  }
}

// ─────────────────────────────────────────────
// LOCATION BANNER
// ─────────────────────────────────────────────
class LocationBanner extends StatefulWidget {
  const LocationBanner({Key? key}) : super(key: key);
  @override State<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends State<LocationBanner> with SingleTickerProviderStateMixin {
  final _svc = LocationService();
  bool _loading = false;
  String? _addr, _err;
  double? _lat, _lng, _acc;

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _detect() async {
    setState(() { _loading = true; _err = null; _addr = null; });
    final r = await _svc.get();
    setState(() {
      _loading = false;
      if (r['ok'] == true) { _lat = r['lat']; _lng = r['lng']; _addr = r['addr']; _acc = r['acc']; }
      else _err = r['err'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: P.navy, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: P.navy.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // header
          Row(children: [
            ScaleTransition(
              scale: _loading ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: P.sage.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(_addr != null ? Icons.location_on : Icons.location_searching,
                    color: P.sage, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delivery Location',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 15, fontFamily: 'Georgia')),
              Text(_addr != null ? 'Location detected' : 'Tap to detect your location',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: _loading ? null : _detect,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: P.sage, borderRadius: BorderRadius.circular(20)),
                child: _loading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_addr != null ? 'Refresh' : 'Detect',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // body
          if (_loading)
            Row(children: [
              SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white.withOpacity(0.5))),
              const SizedBox(width: 10),
              Text('Fetching GPS...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ])
          else if (_err != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
              ]),
            )
          else if (_addr != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place, color: P.blush, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(_addr!, style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w500, height: 1.4))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _chip('LAT', _lat?.toStringAsFixed(5) ?? ''),
                const SizedBox(width: 8),
                _chip('LNG', _lng?.toStringAsFixed(5) ?? ''),
                const Spacer(),
                if (_acc != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: P.sage.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.gps_fixed, color: P.sage, size: 11),
                      const SizedBox(width: 4),
                      Text('+-${_acc!.toStringAsFixed(0)}m',
                          style: const TextStyle(color: P.sage, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ])
          else
            Row(children: [
              Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 14),
              const SizedBox(width: 6),
              Text('Location helps us deliver faster', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, String val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Text('$label  ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────
// HERO BANNER  (redesigned)
// ─────────────────────────────────────────────
class HeroBanner extends StatefulWidget {
  final String username;
  const HeroBanner({Key? key, required this.username}) : super(key: key);
  @override State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: P.navy,
            boxShadow: [
              BoxShadow(
                  color: P.navy.withOpacity(0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 12)),
              BoxShadow(
                  color: P.sage.withOpacity(0.15),
                  blurRadius: 60,
                  offset: const Offset(0, 20)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(fit: StackFit.expand, children: [
              // ── Background image or fallback ──
              Image.asset(
                'assets/images/hero_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _HeroFallback(),
              ),

              // ── Left dark gradient ──
              // ── Left dark gradient (much lighter) ──
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.45, 0.75],
      colors: [
        P.navy.withOpacity(0.82),
        P.navy.withOpacity(0.45),
        Colors.transparent,
      ],
    ),
  ),
),

// ── Bottom fade (subtle only) ──
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      stops: const [0.0, 0.3],
      colors: [
        P.navy.withOpacity(0.30),
        Colors.transparent,
      ],
    ),
  ),
),
              // ── Decorative dot grid (top-right) ──
              Positioned(
                right: -10,
                top: -10,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
              ),

              // ── Decorative circle accent ──
              Positioned(
                right: 60,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: P.sage.withOpacity(0.18), width: 1.5),
                  ),
                ),
              ),
              Positioned(
                right: 90,
                bottom: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: P.blush.withOpacity(0.10), width: 1),
                  ),
                ),
              ),

              // ── Main content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // greeting badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: P.sage.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: P.sage.withOpacity(0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.waving_hand_rounded,
                              color: P.sage, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            'Hello, ${widget.username}',
                            style: const TextStyle(
                                color: P.sage,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // brand name
                    const Text(
                      'penzy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Georgia',
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // tagline with underline accent
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: P.blush, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'your cozy stationery corner',
                          style: TextStyle(
                            color: P.blush,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // pill row
                    Row(
                      children: [
                        _pill(Icons.local_shipping_outlined,
                            'Free delivery > Rs.500', P.sage),
                        const SizedBox(width: 8),
                        _pill(Icons.auto_awesome_outlined,
                            'New arrivals', P.amber),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bottom strip ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [P.sage, P.blush, P.amber, P.lavender],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color accent) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.30), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 13),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
}

// ── Dot grid painter ──────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Fallback background (no image) ───────────
class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A2535),
      child: Stack(
        children: [
          // large blobs
          Positioned(
            right: -30,
            top: -30,
            child: _blob(200, P.sage.withOpacity(0.09)),
          ),
          Positioned(
            right: 80,
            bottom: -50,
            child: _blob(140, P.blush.withOpacity(0.08)),
          ),
          Positioned(
            right: 30,
            top: 60,
            child: _blob(80, P.lavender.withOpacity(0.10)),
          ),
          // icons scattered
          const Positioned(
            right: 28,
            top: 18,
            child: Icon(Icons.menu_book_rounded,
                color: Colors.white12, size: 64),
          ),
          const Positioned(
            right: 110,
            bottom: 24,
            child: Icon(Icons.edit_rounded,
                color: Colors.white10, size: 48),
          ),
          const Positioned(
            right: 60,
            top: 80,
            child: Icon(Icons.brush_rounded,
                color: Colors.white10, size: 36),
          ),
          const Positioned(
            right: 160,
            top: 36,
            child:
                Icon(Icons.push_pin_rounded, color: Colors.white10, size: 28),
          ),
          const Positioned(
            right: 20,
            bottom: 50,
            child: Icon(Icons.star_rounded,
                color: Colors.white10, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _blob(double sz, Color c) => Container(
      width: sz,
      height: sz,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: c));
}

// ─────────────────────────────────────────────
// SECTION HEADING
// ─────────────────────────────────────────────
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeading({Key? key, required this.title,
    this.subtitle, this.icon, this.iconColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? P.sage, size: 20),
                const SizedBox(width: 8),
              ],
              Text(title, style: const TextStyle(color: P.textDark, fontSize: 20,
                  fontWeight: FontWeight.w800, fontFamily: 'Georgia', letterSpacing: -0.3)),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: const TextStyle(color: P.textLight, fontSize: 12,
                  fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
        Container(width: 36, height: 3,
            decoration: BoxDecoration(color: P.sage.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY CHIP ROW
// ─────────────────────────────────────────────
class CategoryChips extends StatelessWidget {
  const CategoryChips({Key? key}) : super(key: key);

  static const _cats = [
    (Icons.edit, 'Pens & Pencils'),
    (Icons.menu_book, 'Notebooks'),
    (Icons.brush, 'Art Supplies'),
    (Icons.push_pin, 'Desk Items'),
    (Icons.card_giftcard, 'Gift Sets'),
    (Icons.highlight, 'Markers'),
    (Icons.folder, 'Folders'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (icon, label) = _cats[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: P.white, borderRadius: BorderRadius.circular(22),
              border: Border.all(color: P.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: P.sage),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: P.textMid, fontWeight: FontWeight.w600)),
            ]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROMO BANNER  (between sections)
// ─────────────────────────────────────────────
class PromoBanner extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title, subtitle;
  final Color bgColor;

  const PromoBanner({Key? key, required this.icon, required this.iconBg,
      required this.title, required this.subtitle, required this.bgColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 14, fontFamily: 'Georgia')),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ]),
        const Spacer(),
        Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 14),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// PRODUCT PAGE
// ─────────────────────────────────────────────
class ProductPage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;
  const ProductPage({Key? key, required this.username, required this.onLogout}) : super(key: key);
  @override _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _db = FirebaseDatabase.instance.ref("products");
  List<Map> products = [];
  Set<String> ratedProducts = {};
  Set<String> reviewedProducts = {};
  final Map<String, TextEditingController> _reviewCtrl = {};
  Map<String, int> selectedRatings = {};
  List<CartItem> cart = [];
  bool _dragOver = false;

  double get total => cart.fold(0.0, (s, i) => s + i.subtotal);
  int get count => cart.fold(0, (s, i) => s + i.quantity);

  @override
  void initState() { super.initState(); _listen(); }

  void _listen() {
    _db.onValue.listen((e) {
      final data = e.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          products = data.entries.map((e) => {
            "id": e.key,
            "name": e.value["name"] ?? '',
            "price": e.value["price"] ?? 0,
            "rating": e.value["rating"] ?? 0,
            "count": e.value["users"] ?? 0,
            // ── FIX: normalise reviews to Map<String,dynamic> regardless of Firebase key type ──
            "reviews": _normaliseReviews(e.value["reviews"]),
            "image": e.value["image"] ?? "",
          }).toList();
        });
      }
    });
  }

  /// Firebase can return reviews with integer keys on web.
  /// We convert to Map<String, dynamic> with string keys safely.
  Map<String, dynamic> _normaliseReviews(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return { for (final e in raw.entries) e.key.toString(): e.value };
    }
    return {};
  }

  void addToCart(Map p) {
    setState(() {
      final i = cart.indexWhere((c) => c.id == p["id"].toString());
      if (i >= 0) cart[i].quantity++; else cart.add(CartItem(product: p));
    });
    PenzyToast.show(context, message: '${p["name"]} added to cart',
        icon: Icons.shopping_bag_outlined, color: P.sage);
  }

  void increaseQty(int i) => setState(() => cart[i].quantity++);
  void decreaseQty(int i) => setState(() {
    if (cart[i].quantity > 1) cart[i].quantity--; else cart.removeAt(i);
  });
  void removeAt(int i, {VoidCallback? done}) {
    final name = cart[i].name;
    setState(() => cart.removeAt(i));
    done?.call();
    PenzyToast.show(context, message: '$name removed', icon: Icons.delete_outline, color: P.rose);
  }
  void clearCart() => setState(() => cart.clear());

  void updateRating(String id, double r) async {
    if (ratedProducts.contains(id)) return;
    final snap = await _db.child(id).get();
    if (!snap.exists) return;
    final data = snap.value as Map;
    final old = double.tryParse(data["rating"].toString()) ?? 0.0;
    final cnt = int.tryParse(data["users"].toString()) ?? 0;
    final avg = ((old * cnt) + r) / (cnt + 1);
    await _db.child(id).update({"rating": double.parse(avg.toStringAsFixed(1)), "users": cnt + 1});
    setState(() { ratedProducts.add(id); selectedRatings[id] = r.toInt(); });
    PenzyToast.show(context, message: 'Rating submitted!', icon: Icons.star, color: P.amber);
  }

  void submitReview(String id) async {
    final txt = _reviewCtrl[id]?.text.trim() ?? '';
    if (txt.isEmpty) return;
    await _db.child(id).child("reviews").push().set({"text": txt});
    _reviewCtrl[id]?.clear();
    setState(() => reviewedProducts.add(id));
    PenzyToast.show(context, message: 'Review submitted!', icon: Icons.rate_review_outlined, color: P.lavender);
  }

  Widget _stars(double rating, {double size = 20}) {
  final full = rating.round().clamp(0, 5);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < full ? Icons.star_rounded : Icons.star_outline_rounded,
      color: P.amber,
      size: size,
      // No fontFamily override here — let it inherit Material Icons
    )),
  );
}
  Widget _starSelector(String id) {
    final cur = selectedRatings[id] ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
        GestureDetector(
          onTap: () => updateRating(id, (i + 1).toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(i < cur ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < cur ? P.amber : P.textLight, size: 30),
          ),
        ))),
      if (cur > 0) ...[
        const SizedBox(height: 4),
        Text('You rated: $cur', style: const TextStyle(color: P.sageDark, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    ]);
  }

  Widget _summaryRow(String l, String v, {Color? vc}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 13, color: P.textMid)),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: vc ?? P.textDark)),
    ],
  );

  void _logout() => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: P.white,
    title: const Text('Log Out?', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w800)),
    content: Text('Leaving penzy as "${widget.username}"?', style: const TextStyle(color: P.textMid)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Stay', style: TextStyle(color: P.sage))),
      TextButton(onPressed: () { Navigator.pop(context); widget.onLogout(); },
          child: const Text('Log Out', style: TextStyle(color: P.rose))),
    ],
  ));

  // ─── Cart bottom sheet ───────────────────
  void showCart() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        void sync(VoidCallback fn) { setState(fn); setM(fn); }
        double sub = cart.fold(0.0, (s, i) => s + i.subtotal);
        double del = sub > 500 ? 0 : 40;
        double grand = sub + del;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(color: P.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: P.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: P.navy, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.shopping_bag_outlined, color: P.sage, size: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: P.textDark, fontFamily: 'Georgia')),
                  Text(cart.isEmpty ? 'Nothing here yet' : '$count item${count == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: P.textLight)),
                ]),
                const Spacer(),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => showDialog(context: ctx, builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: P.white,
                      title: const Text('Clear Cart?', style: TextStyle(fontFamily: 'Georgia')),
                      content: const Text('Remove all items?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: P.sage))),
                        TextButton(onPressed: () { Navigator.pop(ctx); sync(clearCart); },
                            child: const Text('Clear all', style: TextStyle(color: P.rose))),
                      ],
                    )),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: P.rose),
                    label: const Text('Clear', style: TextStyle(color: P.rose, fontSize: 12)),
                  ),
                IconButton(icon: const Icon(Icons.close, color: P.textDark), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20, color: P.border),
            Expanded(
              child: cart.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.shopping_cart_outlined, size: 72, color: P.border),
                      const SizedBox(height: 14),
                      const Text('Your cart is empty', style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600, fontFamily: 'Georgia', color: P.textMid)),
                      const SizedBox(height: 6),
                      const Text('Add some lovely stationery below', style: TextStyle(
                          fontSize: 13, color: P.textLight, fontStyle: FontStyle.italic)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: cart.length,
                      itemBuilder: (_, i) => _cartCard(i, sync),
                    ),
            ),
            if (cart.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: const BoxDecoration(color: P.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: P.border))),
                child: Column(children: [
                  _summaryRow('Subtotal (${cart.length} item${cart.length == 1 ? '' : 's'})', 'Rs.${sub.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _summaryRow('Delivery', del == 0 ? 'FREE!' : 'Rs.${del.toStringAsFixed(0)}',
                      vc: del == 0 ? P.sageDark : null),
                  if (del > 0) ...[
                    const SizedBox(height: 4),
                    Text('Add Rs.${(500 - sub).toStringAsFixed(0)} more for free delivery',
                        style: const TextStyle(fontSize: 11, color: P.rose, fontStyle: FontStyle.italic)),
                  ],
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: P.border)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        fontFamily: 'Georgia', color: P.textDark)),
                    Text('Rs.${grand.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w900, fontFamily: 'Georgia', color: P.textDark)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: P.navy, elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        PenzyToast.show(context, message: 'Order placed successfully!',
                            icon: Icons.celebration_outlined, color: P.sage,
                            duration: const Duration(seconds: 3));
                      },
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Proceed to Checkout', style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700, fontFamily: 'Georgia', color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: P.sage, borderRadius: BorderRadius.circular(8)),
                          child: Text('Rs.${grand.toStringAsFixed(0)}', style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
          ]),
        );
      }),
    );
  }

  Widget _cartCard(int i, void Function(VoidCallback) sync) {
    final item = cart[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: P.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: P.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset("assets/images/${item.product["image"]}", width: 64, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: P.creamDark, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.image_outlined, color: P.textLight, size: 28))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
              fontFamily: 'Georgia', color: P.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('Rs.${item.unitPrice.toStringAsFixed(0)} each', style: const TextStyle(fontSize: 12, color: P.textLight)),
          Text('Rs.${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w800, fontFamily: 'Georgia', color: P.sageDark)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          GestureDetector(
            onTap: () => sync(() => removeAt(i)),
            child: Container(padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: P.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: P.rose, size: 16)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: P.cream, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: P.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => sync(() => decreaseQty(i)),
                child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: item.quantity == 1 ? P.rose.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11))),
                    child: Icon(item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                        size: 16, color: item.quantity == 1 ? P.rose : P.textDark)),
              ),
              Container(width: 36, height: 32, alignment: Alignment.center,
                  child: Text('${item.quantity}', style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: P.textDark))),
              GestureDetector(
                onTap: () => sync(() => increaseQty(i)),
                child: Container(width: 32, height: 32,
                    decoration: const BoxDecoration(color: P.navy,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(11))),
                    child: const Icon(Icons.add, size: 16, color: Colors.white)),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  // ─── Product card (vertical / full width) ───
  Widget _productCard(Map p) {
    final id = p["id"].toString();
    _reviewCtrl.putIfAbsent(id, () => TextEditingController());
    final rating = double.tryParse(p["rating"].toString()) ?? 0.0;
    final cnt    = int.tryParse(p["count"].toString()) ?? 0;
    final reviews = p["reviews"] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(color: P.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: P.border),
          boxShadow: [BoxShadow(color: P.rose.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // image
        // inside _productCard, replace the image Stack child:
Stack(children: [
  ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: Container(
      width: double.infinity,
      height: 280, // ← was 220, bigger image
      color: P.creamDark,
      child: Image.asset(
        "assets/images/${p["image"]}",
        fit: BoxFit.cover, // ← was contain, cover fills the space
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_outlined, color: P.textLight, size: 48),
        ),
      ),
    ),
  ),
  // keep the "hold & drag" badge as-is
  Positioned(
    top: 12, right: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: P.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: P.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.drag_indicator, size: 12, color: P.textLight),
        SizedBox(width: 3),
        Text('hold & drag',
            style: TextStyle(fontSize: 10, color: P.textLight, fontWeight: FontWeight.w500)),
      ]),
    ),
  ),
]),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p["name"].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                fontFamily: 'Georgia', color: P.textDark)),
            const SizedBox(height: 6),
            Row(children: [
              Text('Rs.${p["price"]}', style: const TextStyle(fontWeight: FontWeight.w900,
                  fontFamily: 'Georgia', fontSize: 22, color: P.sageDark)),
              const Spacer(),
              _stars(rating),
              const SizedBox(width: 5),
              Text(rating.toStringAsFixed(1), style: const TextStyle(color: P.textMid, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('($cnt)', style: const TextStyle(color: P.textLight, fontSize: 12)),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1, color: P.border),
            const SizedBox(height: 14),

            // rate
            if (!ratedProducts.contains(id)) ...[
              Row(children: const [
                Icon(Icons.star_rate_outlined, color: P.amber, size: 16),
                SizedBox(width: 6),
                Text('Rate this product', style: TextStyle(color: P.textMid, fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'Georgia')),
              ]),
              const SizedBox(height: 8),
              _starSelector(id),
              const SizedBox(height: 14),
            ],

            // review
            if (!reviewedProducts.contains(id)) ...[
              Row(children: const [
                Icon(Icons.rate_review_outlined, color: P.lavender, size: 16),
                SizedBox(width: 6),
                Text('Write a review', style: TextStyle(color: P.textMid, fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'Georgia')),
              ]),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: P.cream, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: P.border)),
                child: TextField(
                  controller: _reviewCtrl[id], maxLines: 2,
                  style: const TextStyle(color: P.textDark, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Share your thoughts...',
                      hintStyle: TextStyle(color: P.textLight, fontSize: 13),
                      border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: P.lavender),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => submitReview(id),
                  child: const Text('Submit Review', style: TextStyle(color: P.lavender,
                      fontWeight: FontWeight.w700, fontFamily: 'Georgia')),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // reviews list  ← FIXED: safe string access on normalised map
            if (reviews.isNotEmpty) ...[
              const Divider(height: 1, color: P.border),
              const SizedBox(height: 14),
              Row(children: const [
                Icon(Icons.chat_bubble_outline, color: P.lavender, size: 16),
                SizedBox(width: 6),
                Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia', color: P.textDark, fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              ...reviews.entries.map((entry) {
                // Safely extract text regardless of nested structure
                String txt = '';
                final val = entry.value;
                if (val is Map) {
                  txt = val["text"]?.toString() ?? '';
                } else {
                  txt = val?.toString() ?? '';
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: P.cream, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: P.border)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: P.lavender.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.person_outline, color: P.lavender, size: 14)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(txt, style: const TextStyle(color: P.textMid, fontSize: 13, height: 1.4))),
                  ]),
                );
              }),
              const SizedBox(height: 6),
            ],

            // add to cart
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: P.navy, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => addToCart(p),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia', fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

 Widget _miniCard(Map p) {
  final rating = double.tryParse(p["rating"].toString()) ?? 0.0;
  return GestureDetector(
    onTap: () => addToCart(p),
    child: Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: P.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: P.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ← KEY FIX: don't force height
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 110,
              width: double.infinity,
              color: P.creamDark,
              child: Image.asset(
                "assets/images/${p["image"]}",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_outlined, color: P.textLight, size: 32),
                ),
              ),
            ),
          ),
          // details
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p["name"].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    color: P.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs.${p["price"]}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Georgia',
                    color: P.sageDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  _stars(rating, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: P.textLight),
                  ),
                ]),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: P.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  // ─── Horizontal product row ───────────────
  Widget _hRow(String title, String subtitle, IconData icon, Color iconColor, List<Map> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeading(title: title, subtitle: subtitle, icon: icon, iconColor: iconColor),
      SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          itemCount: items.length,
          itemBuilder: (_, i) => _miniCard(items[i]),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Split products for sections
    final topRated = [...products]
      ..sort((a, b) => (double.tryParse(b["rating"].toString()) ?? 0)
          .compareTo(double.tryParse(a["rating"].toString()) ?? 0));
    final bestSellers = topRated.take(products.length).toList();
    final newArrivals = products.reversed.take(products.length).toList();

    return Scaffold(
      backgroundColor: P.cream,
      appBar: AppBar(
        backgroundColor: P.white, elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: P.border)),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.edit_note_rounded, color: P.amber, size: 22),
          SizedBox(width: 6),
          Text('penzy', style: TextStyle(color: P.textDark, fontWeight: FontWeight.w900,
              fontFamily: 'Georgia', fontSize: 22, letterSpacing: -0.5)),
        ]),
        centerTitle: true,
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: P.textDark), onPressed: showCart),
            if (count > 0)
              Positioned(right: 6, top: 6,
                child: Container(padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: P.sage, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('$count', style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w800), textAlign: TextAlign.center)),
              ),
          ]),
          IconButton(icon: const Icon(Icons.logout_rounded), color: P.textMid,
              tooltip: 'Log Out', onPressed: _logout),
        ],
      ),

      body: Stack(children: [
        Center(
          child: SizedBox(
            width: 800,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 110),
              child: ListView(
                children: [
                  // ── Hero ──
                  HeroBanner(username: widget.username),

                  // ── Delivery ──
                  const SectionHeading(title: 'Delivery Location',
                      subtitle: "We'll deliver right to your door",
                      icon: Icons.location_on_outlined, iconColor: P.sage),
                  const LocationBanner(),

                  // ── Categories ──
                  const SectionHeading(title: 'Shop by Category',
                      subtitle: 'Find what you love',
                      icon: Icons.grid_view_rounded, iconColor: P.lavender),
                  const SizedBox(height: 4),
                  const CategoryChips(),

                  // ── Top Rated horizontal row ──
                  _hRow('Top Rated', 'Loved by our community',
                      Icons.star_rounded, P.amber, topRated),

                  // ── Promo banner 1 ──
                  const SizedBox(height: 8),
                  PromoBanner(
                    icon: Icons.local_shipping_outlined,
                    iconBg: P.sage,
                    title: 'Free Delivery',
                    subtitle: 'On orders above Rs.500',
                    bgColor: P.sageDark,
                  ),
                  const SizedBox(height: 4),

                  // ── New Arrivals horizontal row ──
                  _hRow('New Arrivals', 'Fresh picks for your desk',
                      Icons.new_releases_outlined, P.rose, newArrivals),

                  // ── Promo banner 2 ──
                  const SizedBox(height: 4),
                  PromoBanner(
                    icon: Icons.card_giftcard_outlined,
                    iconBg: P.lavender,
                    title: 'Gift a Stationery Set',
                    subtitle: 'Perfect for every occasion',
                    bgColor: const Color(0xFF6B5B95),
                  ),
                  const SizedBox(height: 4),

                  // ── Best Sellers horizontal row ──
                  _hRow('Best Sellers', 'Our most popular picks',
                      Icons.trending_up_rounded, P.navy, bestSellers),

                  // ── All Products section ──
                  const SectionHeading(title: 'All Products',
                      subtitle: 'Browse the full collection',
                      icon: Icons.storefront_outlined, iconColor: P.sageDark),

                  // Full product cards with drag support
                  ...products.map((p) {
                    final id = p["id"].toString();
                    _reviewCtrl.putIfAbsent(id, () => TextEditingController());
                    return LongPressDraggable<Map>(
                      data: p,
                      delay: const Duration(milliseconds: 200),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 180, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: P.navy, borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20, offset: const Offset(0, 8))]),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset("assets/images/${p["image"]}", height: 80, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_outlined, color: Colors.white54, size: 40)),
                            const SizedBox(height: 8),
                            Text(p["name"].toString(), style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Georgia'),
                                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Rs.${p["price"]}', style: const TextStyle(color: P.sage, fontSize: 13,
                                fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.45, child: _productCard(p)),
                      child: _productCard(p),
                    );
                  }).toList(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // ── Floating cart drop zone ──
        Positioned(
          left: 16, right: 16, bottom: 16,
          child: DragTarget<Map>(
            onWillAcceptWithDetails: (d) { setState(() => _dragOver = true); return true; },
            onLeave: (_) => setState(() => _dragOver = false),
            onAcceptWithDetails: (d) { setState(() => _dragOver = false); addToCart(d.data); },
            builder: (_, cand, __) {
              final drag = cand.isNotEmpty || _dragOver;
              return GestureDetector(
                onTap: showCart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
                  height: drag ? 90 : 72,
                  decoration: BoxDecoration(
                    color: drag ? P.sage : P.navy,
                    borderRadius: BorderRadius.circular(24),
                    border: drag ? Border.all(color: Colors.white.withOpacity(0.5), width: 2.5) : null,
                    boxShadow: [BoxShadow(
                        color: drag ? P.sage.withOpacity(0.45) : Colors.black.withOpacity(0.25),
                        blurRadius: drag ? 28 : 16, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: drag ? Colors.white.withOpacity(0.22) : P.sage.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(drag ? Icons.add_shopping_cart_rounded : Icons.shopping_bag_outlined,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(drag ? 'Drop to add to cart!' : 'Cart  -  $count item${count == 1 ? '' : 's'}',
                          style: TextStyle(color: Colors.white.withOpacity(drag ? 1.0 : 0.65),
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Rs.${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Georgia', letterSpacing: 0.5)),
                    ])),
                    if (!drag) ...[
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.drag_indicator, color: Colors.white.withOpacity(0.35), size: 18),
                        const SizedBox(height: 2),
                        Text('drag here', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9)),
                      ]),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: P.sage, borderRadius: BorderRadius.circular(12)),
                        child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CONFIGURATION
// ============================================================
const String supabaseUrl     = 'https://sneobnowfvujsajrgcdl.supabase.co';
const String supabaseAnonKey = 'sb_publishable_pbUPSfEacPPix6n5wG963Q_080Be0Gp';

// ============================================================
// HELPERS
// ============================================================
SupabaseClient get _db => Supabase.instance.client;
String? get _currentUserId => _db.auth.currentUser?.id;

// ============================================================
// MAIN
// ============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

// ============================================================
// THEME NOTIFIER  (dark mode toggle)
// ============================================================
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscription Analytics',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ============================================================
// AUTH WRAPPER
// ============================================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _seenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _db.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _db.auth.currentSession;
    if (session == null) return const LoginScreen();
    final emailConfirmed = _db.auth.currentUser?.emailConfirmedAt != null;
    if (!emailConfirmed) return const EmailVerificationScreen();
    if (!_seenOnboarding) {
      return OnboardingScreen(onDone: () => setState(() => _seenOnboarding = true));
    }
    return const MainTabView();
  }
}

// ============================================================
// ONBOARDING  (3-step swipeable intro)
// ============================================================
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OBPage(
      icon: Icons.subscriptions_rounded,
      color: Color(0xFF1565C0),
      title: 'Manage Your Subscriptions',
      body:
          'Choose from Weekly, Monthly, Annual, or Lifetime plans. '
          'Upgrade, downgrade, or cancel anytime — no hidden fees.',
    ),
    _OBPage(
      icon: Icons.analytics_rounded,
      color: Color(0xFF6A1B9A),
      title: 'Real-Time Analytics',
      body:
          'See your MRR, active subscribers, churn rate, revenue trends, '
          'and referral sources — all backed by live data.',
    ),
    _OBPage(
      icon: Icons.shield_rounded,
      color: Color(0xFF00695C),
      title: 'Secure & Private',
      body:
          'Your data is encrypted end-to-end. Row-Level Security means '
          'only you can see your own records. Cancel whenever you like.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < _pages.length - 1) {
                      _ctrl.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut);
                    } else {
                      widget.onDone();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _page < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OBPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _OBPage(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 80, color: color),
        ),
        const SizedBox(height: 40),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(body,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.6)),
      ]),
    );
  }
}

// ============================================================
// EMAIL VERIFICATION WAITING SCREEN
// ============================================================
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  bool _resent = false;

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _resent = false;
    });
    try {
      final email = _db.auth.currentUser?.email ?? '';
      await _db.auth.resend(type: OtpType.signup, email: email);
      if (mounted) setState(() => _resent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not resend: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _db.auth.currentUser?.email ?? '';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined,
                        size: 56, color: Colors.blue),
                  ),
                  const SizedBox(height: 24),
                  const Text('Check Your Email',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a confirmation link to\n$email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the link in the email to activate your account. '
                    'This page updates automatically once confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  if (_resent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withAlpha(60)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Email resent!',
                                style: TextStyle(color: Colors.green)),
                          ]),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _resending ? null : _resendEmail,
                        icon: _resending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.send_outlined),
                        label: Text(
                            _resending ? 'Sending…' : 'Resend Confirmation Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _db.auth.signOut(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Login'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN / SIGNUP  +  FORGOT PASSWORD
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _countryCtrl  = TextEditingController();

  bool   _isLoading   = false;
  bool   _isLogin     = true;
  bool   _showForgot  = false;
  String _referral    = 'organic';

  static const _referralOptions = [
    'organic', 'google_ads', 'social_media',
    'friend_referral', 'app_store', 'other',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  String _deviceType() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS:     return 'ios';
      case TargetPlatform.macOS:   return 'macos';
      case TargetPlatform.windows: return 'windows';
      case TargetPlatform.linux:   return 'linux';
      default:                     return 'web';
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter your email above first.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _db.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.mark_email_read_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Password reset link sent to $email. Check your inbox.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ]),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ));
      setState(() => _showForgot = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send reset email: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _db.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        final res = await _db.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        if (res.user != null) {
          try {
            await _db.from('users').insert({
              'user_id':         res.user!.id,
              'email':           _emailCtrl.text.trim(),
              'name':            _nameCtrl.text.trim(),
              'signup_date':     DateTime.now().toIso8601String(),
              'country':         _countryCtrl.text.trim().isEmpty
                                     ? null
                                     : _countryCtrl.text.trim(),
              'referral_source': _referral,
              'device_type':     _deviceType(),
              'data_source':     'real_app',
            });
          } catch (_) {}

          await _db.auth.signOut();

          if (!mounted) return;
          setState(() => _isLogin = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.mark_email_read_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Account created! Check ${_emailCtrl.text.trim()} '
                  'and click the confirmation link, then log in.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains('duplicate key') ||
          msg.contains('User already registered')) {
        msg = 'An account with this email already exists. Please log in.';
      } else if (msg.contains('Invalid login credentials')) {
        msg = 'Incorrect email or password.';
      } else if (msg.contains('Email not confirmed')) {
        msg = 'Please confirm your email before logging in. Check your inbox.';
      } else {
        msg = msg
            .replaceAll('PostgrestException(message: ', '')
            .split(', code:')[0];
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _showForgot
                    ? _buildForgotPassword()
                    : _buildLoginSignup(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_reset_rounded, size: 56, color: Colors.blue),
      const SizedBox(height: 16),
      const Text('Reset Password',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'Enter your email and we\'ll send a password reset link.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      const SizedBox(height: 24),
      _field(_emailCtrl, 'Email', Icons.email_outlined,
          type: TextInputType.emailAddress),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Send Reset Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => setState(() => _showForgot = false),
        child: const Text('← Back to Login'),
      ),
    ]);
  }

  Widget _buildLoginSignup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.subscriptions_rounded, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style:
              const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (!_isLogin) ...[
          _field(_nameCtrl, 'Full Name', Icons.person_outline),
          const SizedBox(height: 16),
          _field(_countryCtrl, 'Country (optional)', Icons.flag_outlined),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _referral,
            decoration: InputDecoration(
              labelText: 'How did you hear about us?',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.campaign_outlined),
            ),
            items: _referralOptions
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                          o.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _referral = v);
            },
          ),
          const SizedBox(height: 16),
        ],
        _field(_emailCtrl, 'Email', Icons.email_outlined,
            type: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _field(_passwordCtrl, 'Password', Icons.lock_outline,
            obscure: true),
        if (_isLogin) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showForgot = true),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.blue),
              child: const Text('Forgot Password?'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(_isLogin ? 'Login' : 'Sign Up',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin
              ? 'Need an account? Sign Up'
              : 'Already have an account? Login'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ============================================================
// MAIN TAB VIEW
// ============================================================
class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _idx = 0;

  final _pages = const [
    SubscriptionScreen(),
    AnalyticsScreen(),
    PaymentHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Colors.blue.withAlpha(51),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star, color: Colors.blue),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Colors.blue),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.blue),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUBSCRIPTION SCREEN
// ============================================================
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? _sub;
  bool _loading = false;

  // Plan catalogue  [name, price label, period, features, amount, days, popular]
  static const _plans = [
    _PlanDef('Weekly Plan',  '\$3.99',  '/week',
        ['Basic access', 'Cancel anytime'],
        'weekly',  3.99,   7,   false),
    _PlanDef('Monthly Plan', '\$12.99', '/month',
        ['Full access', 'Cancel anytime', 'Email support'],
        'monthly', 12.99,  30,  true),
    _PlanDef('Annual Plan',  '\$99.99', '/year',
        ['All monthly features', 'Save \$55', 'Priority support', 'Annual report'],
        'annual',  99.99, 365,  false),
    _PlanDef('Lifetime Plan','\$249.99','/once',
        ['Pay once, use forever', 'VIP support', 'Early access'],
        'lifetime',249.99,36500,false),
  ];

  @override
  void initState() {
    super.initState();
    _loadSub();
  }

  Future<void> _loadSub() async {
    if (_currentUserId == null) return;
    try {
      final res = await _db
          .from('subscriptions')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('is_active', true)
          .maybeSingle();
      if (mounted) setState(() => _sub = res);
    } catch (e) {
      debugPrint('Load subscription error: $e');
    }
  }

  Future<void> _subscribe(_PlanDef plan) async {
    setState(() => _loading = true);
    try {
      // Cancel any existing active sub first (upgrade/downgrade)
      if (_sub != null) {
        await _db
            .from('subscriptions')
            .update({
              'is_active': false,
              'cancellation_date': DateTime.now().toIso8601String(),
              'cancellation_reason': 'plan_change',
            })
            .eq('user_id', _currentUserId!)
            .eq('is_active', true);
      }

      final sub = await _db.from('subscriptions').insert({
        'user_id':     _currentUserId,
        'plan_type':   plan.planKey,
        'start_date':  DateTime.now().toIso8601String(),
        'end_date':    DateTime.now()
            .add(Duration(days: plan.days))
            .toIso8601String(),
        'is_active':   true,
        'data_source': 'real_app',
      }).select().single();

      await _db.from('payments').insert({
        'user_id':         _currentUserId,
        'subscription_id': sub['subscription_id'],
        'amount':          plan.amount,
        'payment_date':    DateTime.now().toIso8601String(),
        'status':          'success',
        'data_source':     'real_app',
      });

      await _loadSub();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Subscribed to ${plan.title}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Subscription Error'),
            content: Text('Failed to complete subscription.\n\n$e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _loading = true);
    try {
      await _db.from('subscriptions').update({
        'is_active': false,
        'cancellation_date': DateTime.now().toIso8601String(),
        'cancellation_reason': 'user_cancelled',
      }).eq('user_id', _currentUserId!).eq('is_active', true);

      await _loadSub();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Subscription cancelled'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Cancellation failed: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate =
        _sub != null ? DateTime.tryParse(_sub!['end_date'] ?? '') : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _sub != null
                  ? Column(children: [
                      _activePlanCard(_sub!['plan_type'] as String, endDate),
                      const SizedBox(height: 24),
                      const Text('Switch Plan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._plans
                          .where((p) => p.planKey != _sub!['plan_type'])
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _planCard(p,
                                    isCurrentPlan: false,
                                    isSwitch: true),
                              )),
                    ])
                  : Column(children: [
                      _plansHeroHeader(),
                      const SizedBox(height: 24),
                      ..._plans.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _planCard(p, isCurrentPlan: false),
                          )),
                    ]),
            ),
    );
  }

  Widget _plansHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('LIMITED TIME OFFER',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ),
        const SizedBox(height: 14),
        const Text('Unlock Everything.\nGrow Faster.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.25)),
        const SizedBox(height: 10),
        const Text(
          'Join thousands of users tracking smarter. '
          'Cancel anytime — no questions asked.',
          style:
              TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _heroPill(Icons.analytics_outlined, 'Real-time Analytics'),
          const SizedBox(width: 10),
          _heroPill(Icons.shield_outlined, 'Secure & Private'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _heroPill(Icons.support_agent_outlined, 'Priority Support'),
          const SizedBox(width: 10),
          _heroPill(Icons.cancel_outlined, 'Cancel Anytime'),
        ]),
        const SizedBox(height: 20),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _trustStat('10K+', 'Users'),
                Container(
                    width: 1, height: 28, color: Colors.white30),
                _trustStat('4.8★', 'Rating'),
                Container(
                    width: 1, height: 28, color: Colors.white30),
                _trustStat('99%', 'Uptime'),
              ]),
        ),
      ]),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _trustStat(String value, String label) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      Text(label,
          style:
              const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _activePlanCard(String plan, DateTime? end) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withAlpha(77),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('ACTIVE PLAN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Active',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(plan.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (end != null)
          Text('Renews: ${end.day}/${end.month}/${end.year}',
              style:
                  const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _cancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Subscription',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _planCard(_PlanDef p,
      {required bool isCurrentPlan, bool isSwitch = false}) {
    final popular = p.popular && !isSwitch;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: popular
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: popular
                ? Colors.blue.withAlpha(51)
                : Colors.black.withAlpha(8),
            blurRadius: popular ? 20 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        if (popular)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: const Text('MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSwitch ? 'Switch to ${p.title}' : p.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(p.price,
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900)),
                      Text(p.period,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600)),
                    ]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...p.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Colors.green.withAlpha(26),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 14, color: Colors.green),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(f,
                                style: const TextStyle(fontSize: 14))),
                      ]),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _subscribe(p),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: popular
                          ? Colors.blue
                          : Colors.blue.shade50,
                      foregroundColor:
                          popular ? Colors.white : Colors.blue,
                      elevation: popular ? 4 : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                        isSwitch ? 'Switch Plan' : 'Subscribe Now',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
        ),
      ]),
    );
  }
}

// Plan definition helper
class _PlanDef {
  final String title, price, period, planKey;
  final List<String> features;
  final double amount;
  final int days;
  final bool popular;
  const _PlanDef(this.title, this.price, this.period, this.features,
      this.planKey, this.amount, this.days, this.popular);
}

// ============================================================
// PAYMENT HISTORY SCREEN
// ============================================================
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_currentUserId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _db
          .from('payments')
          .select('payment_id, amount, payment_date, status, subscription_id')
          .eq('user_id', _currentUserId!)
          .order('payment_date', ascending: false);
      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtDate(String? v) {
    if (v == null) return '—';
    final d = DateTime.tryParse(v);
    if (d == null) return v;
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  double get _totalSpend =>
      _payments.fold(0.0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load)
        ],
      ),
      body: _loading
          ? _buildSkeletons()
          : _error != null
              ? _buildError()
              : _payments.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  // ── Skeleton shimmer ─────────────────────────────────────────
  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined,
            size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        const Text('No Payments Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Your payment history will appear here\nonce you subscribe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.star),
          label: const Text('View Plans'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                      '${_payments.length}', 'Transactions',
                      Icons.receipt_long_outlined),
                  Container(
                      width: 1, height: 40, color: Colors.white30),
                  _summaryItem(
                      '\$${_totalSpend.toStringAsFixed(2)}',
                      'Total Spent',
                      Icons.attach_money),
                  Container(
                      width: 1, height: 40, color: Colors.white30),
                  _summaryItem(
                      '${_payments.where((p) => p['status'] == 'success').length}',
                      'Successful',
                      Icons.check_circle_outline),
                ]),
          ),
          // Payment rows
          ..._payments.map((p) {
            final status = p['status'] as String? ?? 'unknown';
            final isSuccess = status == 'success';
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withAlpha(20)
                        : Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment #${(p['payment_id'] as String).substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(_fmtDate(p['payment_date'] as String?),
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withAlpha(20)
                          : Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                          color: isSuccess ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      Text(label,
          style:
              const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}

// Skeleton shimmer card
class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(16),
        ),
        height: 72,
      ),
    );
  }
}

// ============================================================
// ANALYTICS SCREEN  –  100% real Supabase data
// ============================================================
class _AnalyticsData {
  final int totalUsers;
  final double mrr;
  final int activeSubs;
  final double churnRate;
  final List<_MonthRevenue> monthlyRevenue;
  final Map<String, int> planDistribution;
  final Map<String, int> referralSources;
  final List<_MonthUsers> monthlyNewUsers;

  const _AnalyticsData({
    required this.totalUsers,
    required this.mrr,
    required this.activeSubs,
    required this.churnRate,
    required this.monthlyRevenue,
    required this.planDistribution,
    required this.referralSources,
    required this.monthlyNewUsers,
  });
}

class _MonthRevenue {
  final String label;
  final double amount;
  _MonthRevenue(this.label, this.amount);
}

class _MonthUsers {
  final String label;
  final int count;
  _MonthUsers(this.label, this.count);
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _AnalyticsData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Core RPCs — these must exist or we show an error
      final results = await Future.wait([
        _db.rpc('get_total_users'),
        _db.rpc('get_active_subscriptions_count'),
        _db.rpc('get_mrr'),
        _db.rpc('get_churn_rate'),
        _db.rpc('get_monthly_revenue'),
        _db.rpc('get_plan_distribution'),
      ]);

      final totalUsers = (results[0] as int?) ?? 0;
      final activeSubs = (results[1] as int?) ?? 0;
      final mrr        = double.tryParse(results[2].toString()) ?? 0.0;
      final churnRate  = double.tryParse(results[3].toString()) ?? 0.0;

      final monthlyRevenue = (results[4] as List).map((row) {
        return _MonthRevenue(
          row['month_label'] as String,
          double.tryParse(row['revenue'].toString()) ?? 0.0,
        );
      }).toList();

      final planDist = <String, int>{
        'weekly': 0, 'monthly': 0, 'annual': 0, 'lifetime': 0,
      };
      for (final row in (results[5] as List)) {
        final key = row['plan_type'] as String? ?? '';
        planDist[key] = (row['count'] as int?) ?? 0;
      }

      // Optional RPCs — fall back to empty if not yet created in Supabase
      final referralSources = <String, int>{};
      try {
        final rows = await _db.rpc('get_referral_source_breakdown') as List;
        for (final row in rows) {
          final key = (row['referral_source'] as String?) ?? 'unknown';
          referralSources[key] = (row['count'] as int?) ?? 0;
        }
      } catch (_) {
        // RPC not yet created — section will show "No referral data yet"
      }

      final monthlyNewUsers = <_MonthUsers>[];
      try {
        final rows = await _db.rpc('get_monthly_new_users') as List;
        for (final row in rows) {
          monthlyNewUsers.add(_MonthUsers(
            row['month_label'] as String,
            (row['new_users'] as int?) ?? 0,
          ));
        }
      } catch (_) {
        // RPC not yet created — section will show "No signup data yet"
      }

      setState(() {
        _data = _AnalyticsData(
          totalUsers:       totalUsers,
          mrr:              mrr,
          activeSubs:       activeSubs,
          churnRate:        churnRate,
          monthlyRevenue:   monthlyRevenue,
          planDistribution: planDist,
          referralSources:  referralSources,
          monthlyNewUsers:  monthlyNewUsers,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtCurrency(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Dark mode toggle
          IconButton(
            icon: Icon(themeNotifier.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: 'Toggle dark mode',
            onPressed: () => themeNotifier.toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? _buildSkeletons()
          : _error != null
              ? _buildError()
              : _buildDashboard(),
    );
  }

  Widget _buildSkeletons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          children: List.generate(4, (_) => _SkeletonCard()),
        ),
        const SizedBox(height: 16),
        _SkeletonCard(),
        const SizedBox(height: 12),
        _SkeletonCard(),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Could not load analytics',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ]),
      ),
    );
  }

  Widget _buildDashboard() {
    final d = _data!;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('Overview'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: [
              _kpiCard('Total Users', d.totalUsers.toString(),
                  Icons.people_alt_outlined, Colors.blue),
              _kpiCard('Monthly Revenue', _fmtCurrency(d.mrr),
                  Icons.attach_money, Colors.green),
              _kpiCard('Active Subs', d.activeSubs.toString(),
                  Icons.subscriptions_outlined, Colors.purple),
              _kpiCard('Churn Rate',
                  '${d.churnRate.toStringAsFixed(1)}%',
                  Icons.trending_down, Colors.orange),
            ],
          ),
          const SizedBox(height: 28),

          // Revenue chart
          _sectionLabel('Revenue – Last 6 Months'),
          const SizedBox(height: 12),
          _revenueChart(d.monthlyRevenue),
          const SizedBox(height: 28),

          // User growth chart
          _sectionLabel('New Users – Last 6 Months'),
          const SizedBox(height: 12),
          _userGrowthChart(d.monthlyNewUsers),
          const SizedBox(height: 28),

          // Plan distribution
          _sectionLabel('Active Subscriptions by Plan'),
          const SizedBox(height: 12),
          _planBreakdown(d.planDistribution, d.activeSubs),
          const SizedBox(height: 28),

          // Referral source breakdown
          _sectionLabel('Referral Sources'),
          const SizedBox(height: 12),
          _referralBreakdown(d.referralSources),
          const SizedBox(height: 28),

          // Insight banner
          _insightBanner(d),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }

  Widget _kpiCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ]),
          ]),
    );
  }

  Widget _revenueChart(List<_MonthRevenue> months) {
    final maxVal = months
        .map((m) => m.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    const availableHeight = 160.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmtCurrency(maxVal),
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11)),
          Text('Pull down to refresh',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: availableHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: months.asMap().entries.map((entry) {
              final isLast = entry.key == months.length - 1;
              final m = entry.value;
              final frac = maxVal > 0 ? (m.amount / maxVal) : 0.0;
              final barH = availableHeight * frac;

              // MoM growth rate
              String? growthLabel;
              if (entry.key > 0 && months[entry.key - 1].amount > 0) {
                final prev = months[entry.key - 1].amount;
                final pct =
                    ((m.amount - prev) / prev * 100).toStringAsFixed(0);
                growthLabel =
                    '${m.amount >= prev ? '+' : ''}$pct%';
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (growthLabel != null && isLast)
                          Text(growthLabel,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: growthLabel.startsWith('+')
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold)),
                        if (m.amount > 0)
                          Text(_fmtCurrency(m.amount),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isLast
                                      ? Colors.blue
                                      : Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          height: barH.clamp(4.0, availableHeight),
                          decoration: BoxDecoration(
                            gradient: isLast
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF42A5F5)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter)
                                : null,
                            color: isLast
                                ? null
                                : Colors.blue.withAlpha(46),
                            borderRadius:
                                const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(m.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isLast
                                    ? Colors.blue
                                    : Colors.grey.shade600)),
                      ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // User growth bar chart
  Widget _userGrowthChart(List<_MonthUsers> months) {
    final maxVal = months
        .map((m) => m.count)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    const availableHeight = 140.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: months.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No signup data yet',
                    style: TextStyle(color: Colors.grey)),
              ))
          : SizedBox(
              height: availableHeight + 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: months.asMap().entries.map((entry) {
                  final isLast = entry.key == months.length - 1;
                  final m = entry.value;
                  final frac =
                      maxVal > 0 ? (m.count / maxVal) : 0.0;
                  final barH = availableHeight * frac;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (m.count > 0)
                              Text('${m.count}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isLast
                                          ? Colors.purple
                                          : Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              width: double.infinity,
                              height: barH.clamp(4.0, availableHeight),
                              decoration: BoxDecoration(
                                gradient: isLast
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF6A1B9A),
                                          Color(0xFFAB47BC)
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter)
                                    : null,
                                color: isLast
                                    ? null
                                    : Colors.purple.withAlpha(46),
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(m.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isLast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isLast
                                        ? Colors.purple
                                        : Colors.grey.shade600)),
                          ]),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _planBreakdown(Map<String, int> dist, int total) {
    final colors = {
      'weekly': Colors.teal,
      'monthly': Colors.blue,
      'annual': Colors.purple,
      'lifetime': Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: total == 0
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No active subscriptions yet',
                    style: TextStyle(color: Colors.grey)),
              ))
          : Column(
              children: dist.entries.map((e) {
                final frac = total > 0 ? e.value / total : 0.0;
                final col = colors[e.key] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(e.key.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ]),
                              Text(
                                '${e.value}  (${(frac * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13)),
                            ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 8,
                            backgroundColor: col.withAlpha(26),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(col),
                          ),
                        ),
                      ]),
                );
              }).toList(),
            ),
    );
  }

  // Referral source breakdown
  Widget _referralBreakdown(Map<String, int> sources) {
    final total = sources.values.fold(0, (a, b) => a + b);
    final colors = [
      Colors.blue, Colors.purple, Colors.teal, Colors.orange,
      Colors.pink, Colors.indigo,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: total == 0
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No referral data yet',
                    style: TextStyle(color: Colors.grey)),
              ))
          : Column(
              children: sources.entries.toList().asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final frac = total > 0 ? entry.value / total : 0.0;
                final col = colors[idx % colors.length];
                final label = entry.key.replaceAll('_', ' ').toUpperCase();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: col,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ]),
                              Text(
                                  '${entry.value}  (${(frac * 100).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                            ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 8,
                            backgroundColor: col.withAlpha(26),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(col),
                          ),
                        ),
                      ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _insightBanner(_AnalyticsData d) {
    String insight;
    if (d.activeSubs == 0) {
      insight =
          'No active subscriptions yet — share the app to get your first subscriber!';
    } else if (d.churnRate > 10) {
      insight = 'Churn is at ${d.churnRate.toStringAsFixed(1)}% this month. '
          'Consider a win-back campaign for recently cancelled users.';
    } else {
      final topPlan = d.planDistribution.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      insight = '${topPlan.toUpperCase()} is your most popular plan with '
          '${d.planDistribution[topPlan]} active subscribers. '
          'Revenue this month: ${_fmtCurrency(d.mrr)}.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline,
            color: Colors.white, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Insight',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(insight,
                    style: const TextStyle(color: Colors.white70)),
              ]),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold));
  }
}

// ============================================================
// PROFILE SCREEN
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_currentUserId == null) return;
    try {
      final user = await _db
          .from('users')
          .select(
              'name, email, signup_date, country, referral_source, device_type')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      final sub = await _db
          .from('subscriptions')
          .select('plan_type, start_date, end_date, is_active')
          .eq('user_id', _currentUserId!)
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) setState(() { _user = user; _sub = sub; });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.blue,
            actions: [
              // Dark mode toggle shortcut in profile too
              IconButton(
                icon: Icon(
                  themeNotifier.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Colors.white,
                ),
                onPressed: () => themeNotifier.toggle(),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _db.auth.signOut(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user?['name'] ?? 'Loading...',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _user?['email'] ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_user != null)
                      Wrap(spacing: 8, children: [
                        if (_user!['country'] != null)
                          _chip(Icons.flag_outlined, _user!['country']),
                        if (_user!['referral_source'] != null)
                          _chip(
                            Icons.campaign_outlined,
                            (_user!['referral_source'] as String)
                                .replaceAll('_', ' '),
                          ),
                        if (_user!['device_type'] != null)
                          _chip(Icons.devices_outlined,
                              _user!['device_type']),
                      ]),
                    const SizedBox(height: 24),
                    const Text('Account Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _settingsCard([
                      _tile(Icons.person_outline, 'Personal Information',
                          Colors.blue,
                          onTap: () => _showPersonalInfo(context)),
                      _tile(Icons.notifications_none, 'Notifications',
                          Colors.orange,
                          onTap: () => _showNotifications(context)),
                      _tile(Icons.security, 'Security & Privacy',
                          Colors.green,
                          onTap: () => _showSecurityPrivacy(context)),
                      _tile(Icons.feedback_outlined, 'Send Feedback',
                          Colors.indigo,
                          onTap: () => _showFeedback(context)),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Subscription',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _settingsCard([
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.purple.withAlpha(26),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.star,
                              color: Colors.purple),
                        ),
                        title: const Text('Current Plan',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _sub != null
                                ? '${(_sub!['plan_type'] as String).toUpperCase()} PLAN'
                                : 'FREE PLAN',
                            style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Use the Plans tab to manage your subscription'),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          child: const Text('Manage'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // App preferences
                    const Text('Appearance',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _settingsCard([
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(40),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(
                            themeNotifier.isDark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: themeNotifier.isDark
                                ? Colors.amber
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: const Text('Dark Mode',
                            style: TextStyle(
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          themeNotifier.isDark ? 'On' : 'Off',
                          style: TextStyle(
                              color: Colors.grey.shade500),
                        ),
                        trailing: Switch(
                          value: themeNotifier.isDark,
                          onChanged: (_) => themeNotifier.toggle(),
                          activeColor: Colors.blue,
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14, color: Colors.blue),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue.withAlpha(20),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: children
            .expand((w) =>
                [w, if (w != children.last) const Divider(height: 1)])
            .toList(),
      ),
    );
  }

  Widget _tile(IconData icon, String title, Color color,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showPersonalInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonalInfoSheet(user: _user),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(subscription: _sub),
    );
  }

  void _showSecurityPrivacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SecurityPrivacySheet(),
    );
  }

  void _showFeedback(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedbackSheet(),
    );
  }
}

// ============================================================
// FEEDBACK SHEET
// ============================================================
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _ctrl = TextEditingController();
  String _type = 'general';
  int _rating = 0;
  bool _sending = false;
  bool _sent = false;

  static const _types = [
    ('general',     'General Feedback'),
    ('bug',         'Bug Report'),
    ('feature',     'Feature Request'),
    ('billing',     'Billing Issue'),
  ];

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please write something before submitting.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _sending = true);
    try {
      await _db.from('feedback').insert({
        'user_id':      _currentUserId,
        'feedback_type': _type,
        'rating':       _rating > 0 ? _rating : null,
        'message':      _ctrl.text.trim(),
        'submitted_at': DateTime.now().toIso8601String(),
      });
      if (mounted) setState(() { _sent = true; _sending = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.indigo.withAlpha(20),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.feedback_outlined,
                      color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send Feedback',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('Help us improve',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ]),
              ]),
              const SizedBox(height: 24),

              if (_sent)
                Column(children: [
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Icon(Icons.check_circle_outline,
                          size: 56, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text('Thanks for your feedback!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Your message has been received. '
                        'We read every submission.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ])
              else ...[
                // Feedback type
                const Text('Type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _types.map((t) {
                    final selected = _type == t.$1;
                    return ChoiceChip(
                      label: Text(t.$2),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _type = t.$1),
                      selectedColor: Colors.indigo.withAlpha(40),
                      labelStyle: TextStyle(
                          color: selected
                              ? Colors.indigo
                              : null,
                          fontWeight: selected
                              ? FontWeight.bold
                              : null),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Star rating
                const Text('Rating (optional)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () =>
                          setState(() => _rating = i + 1),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Message
                const Text('Message',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Tell us what\'s on your mind…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.send_outlined),
                    label: Text(_sending ? 'Sending…' : 'Submit Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ]),
      ),
    );
  }
}

// ============================================================
// PERSONAL INFORMATION SHEET
// ============================================================
class _PersonalInfoSheet extends StatelessWidget {
  final Map<String, dynamic>? user;
  const _PersonalInfoSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    String fmt(String? v) => (v == null || v.isEmpty) ? '—' : v;
    String month(int m) => [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ][m - 1];
    String fmtDate(String? v) {
      if (v == null) return '—';
      final d = DateTime.tryParse(v);
      if (d == null) return v;
      return '${d.day} ${month(d.month)} ${d.year}';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person_outline,
                      color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('Your account details',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ]),
              ]),
              const SizedBox(height: 28),
              if (user == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                _infoRow(Icons.badge_outlined, 'Full Name',
                    fmt(user!['name'])),
                _infoRow(Icons.email_outlined, 'Email',
                    fmt(user!['email'])),
                _infoRow(Icons.flag_outlined, 'Country',
                    fmt(user!['country'])),
                _infoRow(Icons.calendar_today_outlined, 'Member Since',
                    fmtDate(user!['signup_date'])),
                _infoRow(
                    Icons.campaign_outlined,
                    'Referred Via',
                    fmt((user!['referral_source'] as String?)
                        ?.replaceAll('_', ' '))),
                _infoRow(Icons.devices_outlined, 'Device',
                    fmt(user!['device_type'])),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withAlpha(40)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'To update your name, country, or other details, '
                        'please use the feedback form or contact support.',
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
            ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ]),
        ),
      ]),
    );
  }
}

// ============================================================
// NOTIFICATIONS SHEET
// ============================================================
class _NotificationsSheet extends StatefulWidget {
  final Map<String, dynamic>? subscription;
  const _NotificationsSheet({required this.subscription});

  @override
  State<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _expiryAlert = true;
  bool _paymentReminder = true;
  bool _newFeatures = false;
  bool _weeklyDigest = true;
  bool _promoOffers = false;

  @override
  Widget build(BuildContext context) {
    DateTime? endDate;
    int? daysLeft;
    if (widget.subscription != null) {
      endDate =
          DateTime.tryParse(widget.subscription!['end_date'] ?? '');
      if (endDate != null) {
        daysLeft = endDate.difference(DateTime.now()).inDays;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.notifications_none,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('Manage your alerts',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ]),
              ]),
              const SizedBox(height: 20),
              if (daysLeft != null && daysLeft <= 30)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: daysLeft <= 7
                          ? [
                              Colors.red.shade700,
                              Colors.red.shade400
                            ]
                          : [
                              Colors.orange.shade700,
                              Colors.orange.shade400
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(
                        daysLeft <= 7
                            ? Icons.warning_amber_rounded
                            : Icons.access_time_rounded,
                        color: Colors.white,
                        size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(
                              daysLeft <= 0
                                  ? 'Plan Expired'
                                  : 'Plan Expiring Soon',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(
                              daysLeft <= 0
                                  ? 'Your plan has expired. Renew now to keep access.'
                                  : 'Your plan expires in $daysLeft day${daysLeft == 1 ? "" : "s"}. '
                                      'Renew now to avoid interruption.',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4)),
                        ])),
                  ]),
                ),
              if (daysLeft == null || daysLeft > 30)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          const Text('Plan Active',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              daysLeft != null
                                  ? 'Your plan is active with $daysLeft days remaining.'
                                  : 'You are on a free plan.',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 13)),
                        ])),
                  ]),
                ),
              _sectionHeader('Plan & Billing'),
              _toggleTile(
                icon: Icons.timer_outlined,
                color: Colors.orange,
                title: 'Plan Expiry Alerts',
                subtitle:
                    'Notify 7 and 3 days before your plan expires',
                value: _expiryAlert,
                onChanged: (v) =>
                    setState(() => _expiryAlert = v),
              ),
              _toggleTile(
                icon: Icons.receipt_long_outlined,
                color: Colors.blue,
                title: 'Payment Reminders',
                subtitle: 'Remind me before each billing cycle',
                value: _paymentReminder,
                onChanged: (v) =>
                    setState(() => _paymentReminder = v),
              ),
              const SizedBox(height: 8),
              _sectionHeader('App Updates'),
              _toggleTile(
                icon: Icons.new_releases_outlined,
                color: Colors.purple,
                title: 'New Features',
                subtitle:
                    'Be first to know about new functionality',
                value: _newFeatures,
                onChanged: (v) =>
                    setState(() => _newFeatures = v),
              ),
              _toggleTile(
                icon: Icons.summarize_outlined,
                color: Colors.teal,
                title: 'Weekly Digest',
                subtitle:
                    'Summary of your account activity every Monday',
                value: _weeklyDigest,
                onChanged: (v) =>
                    setState(() => _weeklyDigest = v),
              ),
              const SizedBox(height: 8),
              _sectionHeader('Offers'),
              _toggleTile(
                icon: Icons.local_offer_outlined,
                color: Colors.pink,
                title: 'Promotional Offers',
                subtitle:
                    'Discounts and special deals tailored for you',
                value: _promoOffers,
                onChanged: (v) =>
                    setState(() => _promoOffers = v),
              ),
              const SizedBox(height: 16),
            ]),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.8)),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ============================================================
// SECURITY & PRIVACY SHEET
// ============================================================
class _SecurityPrivacySheet extends StatelessWidget {
  const _SecurityPrivacySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.security,
                      color: Colors.green, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security & Privacy',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('Your data, your control',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ]),
              ]),
              const SizedBox(height: 24),
              _secCard(
                context: context,
                icon: Icons.lock_outline,
                color: Colors.blue,
                title: 'Password',
                body: 'Your password is encrypted and never stored in plain text. '
                    'To change it, use "Forgot Password" on the login screen.',
                actionLabel: 'How to Change',
                onAction: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(
                        content: Text(
                            'Log out and use "Forgot Password" on the login screen.'))),
              ),
              const SizedBox(height: 12),
              _secCard(
                context: context,
                icon: Icons.devices_outlined,
                color: Colors.purple,
                title: 'Active Sessions',
                body: 'You are currently signed in on this device. '
                    'Signing out will end this session immediately.',
                actionLabel: 'Sign Out',
                actionColor: Colors.red,
                onAction: () {
                  Navigator.pop(context);
                  Supabase.instance.client.auth.signOut();
                },
              ),
              const SizedBox(height: 12),
              _secCard(
                context: context,
                icon: Icons.privacy_tip_outlined,
                color: Colors.teal,
                title: 'Data We Collect',
                body: 'We collect your name, email, country, device type, '
                    'subscription history, and payment records. '
                    'This data is used solely to operate and improve the app.',
              ),
              const SizedBox(height: 12),
              _secCard(
                context: context,
                icon: Icons.storage_outlined,
                color: Colors.orange,
                title: 'Data Storage & Security',
                body: 'All data is stored on Supabase, hosted on AWS. '
                    'Row-Level Security (RLS) ensures you can only access '
                    'your own records. Connections are encrypted with TLS 1.3.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(10),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.red.withAlpha(40)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Icon(Icons.delete_forever_outlined,
                        color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text('Delete Account',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                            fontSize: 15)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account permanently removes all your data. '
                    'This action cannot be undone.',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Account?'),
                        content: const Text(
                            'All your data will be permanently deleted. '
                            'This cannot be reversed. Are you sure?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Please contact support to delete your account.'),
                              ));
                            },
                            child: Text('Delete',
                                style: TextStyle(
                                    color: Colors.red.shade600)),
                          ),
                        ],
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Request Account Deletion →'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
      ),
    );
  }

  Widget _secCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    String? actionLabel,
    Color? actionColor,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 10),
        Text(body,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5)),
        if (actionLabel != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: actionColor ?? Colors.blue,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('$actionLabel →'),
          ),
        ],
      ]),
    );
  }
}
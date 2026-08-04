import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'bootstrap/platform_init.dart';
import 'config/dev_flags.dart';
import 'firebase_options.dart';
import 'navigation/voice_guide_route_observer.dart';
import 'screens/admin_password_reset_page.dart';
import 'screens/auth_wrapper.dart';
import 'screens/firebase_test_page.dart';
import 'screens/fix_admin_page.dart';
import 'screens/force_create_admin_page.dart';
import 'screens/main_shell_page.dart';
import 'screens/payment_cancel_page.dart';
import 'screens/payment_success_page.dart';
import 'screens/premium_splash_screen.dart';
import 'screens/quick_admin_setup_page.dart';
import 'admin/screens/admin_login_page.dart';
import 'services/audio_settings_service.dart';
import 'services/measurement_service.dart';
import 'services/voice_guide_service.dart';
import 'theme/app_theme.dart';

/// RevenueCat public SDK key for the App Store app (iOS only for now).
const String _revenueCatAppleApiKey = 'appl_BKviFlVTiXyPpbGZHKpeqdNBlMj';

String _normalizePath(String path) {
  var normalized = path;
  if (normalized.isEmpty) return '/';
  if (!normalized.startsWith('/')) normalized = '/$normalized';
  while (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

bool _looksLikePaymentCallback(Uri uri) {
  final params = uri.queryParameters;
  return params.containsKey('checkout_id') ||
      params.containsKey('checkoutId') ||
      params.containsKey('payment_id') ||
      params.containsKey('paymentId') ||
      params.containsKey('subscription_id') ||
      params.containsKey('subscriptionId');
}

String _resolveInitialRoute() {
  if (kIsWeb) {
    final uri = Uri.base;
    final path = _normalizePath(uri.path);
    if (path == '/payment-success') return '/payment-success';
    if (path == '/payment-cancel') return '/payment-cancel';
    if (_looksLikePaymentCallback(uri)) return '/payment-success';
  }
  return '/';
}

Future<void> _initRevenueCatIfNeeded() async {
  // iOS App Store only for now — do not configure on Android/web/desktop.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

  try {
    final configuration = PurchasesConfiguration(_revenueCatAppleApiKey);
    await Purchases.configure(configuration);
    debugPrint('RevenueCat configured for iOS');
  } catch (e, stackTrace) {
    // Never block app startup if RevenueCat fails to initialize.
    debugPrint('RevenueCat init failed: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _initializeAppServices() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await platformInit();
  await MeasurementService.instance.init();
  await AudioSettingsService.instance.init();
  // Registers pauseOverlappingAudio so cooking ambience never overlaps TTS.
  VoiceGuideService.instance;
  await _initRevenueCatIfNeeded();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kTestSubscriptionBypass) {
    // Visible in Debug / Profile / Release console logs.
    debugPrint('TEST SUBSCRIPTION BYPASS ACTIVE');
  }

  // Show the premium splash immediately so startup work never leaves a blank
  // white screen. Heavy init runs concurrently under the splash.
  runApp(const _AppBootstrap());
}

/// Covers native → Flutter handoff with splash while services initialize.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  static const _minSplash = Duration(milliseconds: 1250);

  bool _ready = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    final minDelay = Future<void>.delayed(_minSplash);
    Object? error;
    await Future.wait<void>([
      minDelay,
      _initializeAppServices().catchError((Object e, StackTrace stackTrace) {
        debugPrint('App bootstrap failed: $e');
        debugPrint('$stackTrace');
        error = e;
      }),
    ]);
    if (!mounted) return;
    setState(() {
      _initError = error;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const PremiumSplashScreen(),
      );
    }

    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup failed. Please restart the app.\n$_initError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return const FoodGeniusAIApp();
  }
}

class FoodGeniusAIApp extends StatelessWidget {
  const FoodGeniusAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodGeniusAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [voiceGuideRouteObserver],
      initialRoute: _resolveInitialRoute(),
      routes: {
        '/': (context) => const AuthWrapper(),
        '/landing': (context) => const MainShellPage(),
        '/payment-success': (context) => const PaymentSuccessPage(),
        '/payment-cancel': (context) => const PaymentCancelPage(),
        '/admin': (context) => const AdminLoginPage(),
        '/setup-admin': (context) => const QuickAdminSetupPage(),
        '/test-firebase': (context) => const FirebaseTestPage(),
        '/fix-admin': (context) => const FixAdminPage(),
        '/force-admin': (context) => const ForceCreateAdminPage(),
        '/reset-admin': (context) => const AdminPasswordResetPage(),
      },
    );
  }
}

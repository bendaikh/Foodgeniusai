import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'bootstrap/platform_init.dart';
import 'navigation/voice_guide_route_observer.dart';
import 'services/audio_settings_service.dart';
import 'services/measurement_service.dart';
import 'services/voice_guide_service.dart';
import 'screens/auth_wrapper.dart';
import 'screens/main_shell_page.dart';
import 'screens/onboarding_flow_page.dart';
import 'admin/screens/admin_login_page.dart';
import 'screens/quick_admin_setup_page.dart';
import 'screens/firebase_test_page.dart';
import 'screens/admin_password_reset_page.dart';
import 'screens/fix_admin_page.dart';
import 'screens/force_create_admin_page.dart';
import 'screens/payment_success_page.dart';
import 'screens/payment_cancel_page.dart';

/// RevenueCat public SDK key for the App Store app (iOS only for now).
const String _revenueCatAppleApiKey = 'appl_BKviFlVTiXyPpbGZHKpeqdNBlMj';

const String _revenueCatGoogleApiKey = "goog_dLgTZFbkfXhqbBJSjtpTStTVHnZ";

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
  // Configure RevenueCat on iOS and Android only — skip web/desktop.
  if (kIsWeb) return;

  final String apiKey;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    apiKey = _revenueCatAppleApiKey;
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    apiKey = _revenueCatGoogleApiKey;
  } else {
    return;
  }

  try {
    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
    debugPrint(
      defaultTargetPlatform == TargetPlatform.iOS
          ? 'RevenueCat configured for iOS'
          : 'RevenueCat configured for Android',
    );
  } catch (e, stackTrace) {
    // Never block app startup if RevenueCat fails to initialize.
    debugPrint('RevenueCat init failed: $e');
    debugPrint('$stackTrace');
  }
}

/// Android only: true when the user has never completed the first-launch
/// onboarding flow. iOS and Web never show onboarding and are unaffected.
Future<bool> _shouldShowAndroidOnboarding() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OnboardingFlowPage.completedPrefsKey) != true;
  } catch (e) {
    debugPrint('Onboarding pref read failed: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await platformInit();
  await MeasurementService.instance.init();
  await AudioSettingsService.instance.init();
  // Registers pauseOverlappingAudio so cooking ambience never overlaps TTS.
  VoiceGuideService.instance;
  await _initRevenueCatIfNeeded();
  final showAndroidOnboarding = await _shouldShowAndroidOnboarding();

  runApp(FoodGeniusAIApp(showAndroidOnboarding: showAndroidOnboarding));
}

class FoodGeniusAIApp extends StatelessWidget {
  const FoodGeniusAIApp({super.key, this.showAndroidOnboarding = false});

  final bool showAndroidOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Genius AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [voiceGuideRouteObserver],
      initialRoute:
          showAndroidOnboarding ? '/onboarding' : _resolveInitialRoute(),
      routes: {
        '/': (context) => const AuthWrapper(),
        '/onboarding': (context) => const OnboardingFlowPage(),
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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'bootstrap/platform_init.dart';
import 'screens/auth_wrapper.dart';
import 'screens/landing_page.dart';
import 'admin/screens/admin_login_page.dart';
import 'screens/quick_admin_setup_page.dart';
import 'screens/firebase_test_page.dart';
import 'screens/admin_password_reset_page.dart';
import 'screens/fix_admin_page.dart';
import 'screens/force_create_admin_page.dart';
import 'screens/payment_success_page.dart';
import 'screens/payment_cancel_page.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await platformInit();

  runApp(const FoodGeniusAIApp());
}

class FoodGeniusAIApp extends StatelessWidget {
  const FoodGeniusAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodGeniusAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: _resolveInitialRoute(),
      routes: {
        '/': (context) => const AuthWrapper(),
        '/landing': (context) => const LandingPage(),
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

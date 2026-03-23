import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';
import 'screens/landing_page.dart';
import 'admin/screens/admin_login_page.dart';
import 'screens/quick_admin_setup_page.dart';
import 'screens/firebase_test_page.dart';
import 'screens/admin_password_reset_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remove the # from URLs
  usePathUrlStrategy();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const GourmetAIApp());
}

class GourmetAIApp extends StatelessWidget {
  const GourmetAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GourmetAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/landing': (context) => const LandingPage(),
        '/admin': (context) => const AdminLoginPage(),
        '/setup-admin': (context) => const QuickAdminSetupPage(),
        '/test-firebase': (context) => const FirebaseTestPage(),
        '/fix-admin': (context) => const AdminPasswordResetPage(),
      },
    );
  }
}

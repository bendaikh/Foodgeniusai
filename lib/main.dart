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

late final Future<FirebaseApp> _firebaseInit;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  _firebaseInit = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: _FirebaseGate(child: const AuthWrapper()),
      routes: {
        '/landing': (context) => _FirebaseGate(child: const LandingPage()),
        '/admin': (context) => _FirebaseGate(child: const AdminLoginPage()),
        '/setup-admin': (context) => _FirebaseGate(child: const QuickAdminSetupPage()),
        '/test-firebase': (context) => _FirebaseGate(child: const FirebaseTestPage()),
        '/fix-admin': (context) => _FirebaseGate(child: const AdminPasswordResetPage()),
      },
    );
  }
}

class _FirebaseGate extends StatelessWidget {
  final Widget child;
  
  const _FirebaseGate({required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to connect. Please refresh.',
                      style: TextStyle(color: AppTheme.greyText, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          return child;
        }
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}

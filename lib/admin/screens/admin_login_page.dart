import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/admin_setup_service.dart';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final AdminSetupService _adminSetup = AdminSetupService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCreatingAdmin = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is already logged in, check if admin
      final isAdmin = await _authService.isAdmin();
      
      if (isAdmin && mounted) {
        // Already logged in as admin, go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            size: 64,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'GourmetAI',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Admin Panel',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Access your admin dashboard',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'admin@gourmetai.com',
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.greyText),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppTheme.greyText),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.greyText,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Secure Admin Access',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.greyText),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'First time setup?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isCreatingAdmin ? null : _createAdminAccount,
                  icon: _isCreatingAdmin
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                      : const Icon(Icons.add_moderator, size: 18),
                  label: Text(_isCreatingAdmin ? 'Creating...' : 'Create Admin Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email: admin@gourmetai.com\nPassword: Admin123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.greyText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/fix-admin');
                  },
                  icon: const Icon(Icons.build, size: 16, color: Colors.orange),
                  label: const Text(
                    'Having login issues? Click here to fix',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdminAccount() async {
    setState(() => _isCreatingAdmin = true);

    try {
      await _adminSetup.createDefaultAdmin();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Admin account created!\n\nYou can now log in with:\nadmin@gourmetai.com / Admin123456'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Pre-fill the login form
        _emailController.text = 'admin@gourmetai.com';
        _passwordController.text = 'Admin123456';
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('email-already-in-use')) {
          message = '✅ Admin account already exists!\n\nUse:\nadmin@gourmetai.com / Admin123456';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: message.contains('✅') ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingAdmin = false);
    }
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential == null) {
        throw 'Login failed';
      }

      // Check if user is admin
      final isAdmin = await _authService.isAdmin();

      if (!isAdmin) {
        // Not an admin - sign out and show error
        await _authService.signOut();
        throw 'Access denied. Admin privileges required.';
      }

      // Success - navigate to admin dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = e.toString();
      
      // Make error messages user-friendly
      if (errorMessage.contains('user-not-found')) {
        errorMessage = 'No account found with this email';
      } else if (errorMessage.contains('wrong-password')) {
        errorMessage = 'Incorrect password';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (errorMessage.contains('user-disabled')) {
        errorMessage = 'This account has been disabled';
      } else if (errorMessage.contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later';
      } else if (errorMessage.contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection';
      }
      
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

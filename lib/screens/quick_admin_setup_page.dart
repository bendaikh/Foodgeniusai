import 'package:flutter/material.dart';
import '../services/admin_setup_service.dart';
import '../theme/app_theme.dart';

/// Quick Admin Setup Page
/// Use this to create the admin account manually
class QuickAdminSetupPage extends StatefulWidget {
  const QuickAdminSetupPage({super.key});

  @override
  State<QuickAdminSetupPage> createState() => _QuickAdminSetupPageState();
}

class _QuickAdminSetupPageState extends State<QuickAdminSetupPage> {
  final AdminSetupService _adminSetup = AdminSetupService();
  bool _isCreating = false;
  String _message = '';
  Color _messageColor = Colors.white;

  Future<void> _createAdmin() async {
    setState(() {
      _isCreating = true;
      _message = 'Creating admin account...';
      _messageColor = Colors.orange;
    });

    try {
      await _adminSetup.createDefaultAdmin();
      
      setState(() {
        _isCreating = false;
        _message = '✅ Admin account created successfully!\n\n'
            'Email: admin@gourmetai.com\n'
            'Password: Admin123456\n\n'
            'You can now log in with these credentials.';
        _messageColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
        _message = '❌ Error: $e';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create Admin Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Click the button below to create the default admin account in Firebase Authentication.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 48),
                
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createAdmin,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_moderator),
                  label: Text(_isCreating ? 'Creating...' : 'Create Admin Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _messageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _messageColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _messageColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Default Admin Credentials:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Email: admin@gourmetai.com',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Password: Admin123456',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '⚠️ Note: If the account already exists, this will update the existing user to have admin privileges.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

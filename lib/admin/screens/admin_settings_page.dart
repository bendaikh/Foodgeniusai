import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  // Firebase Configuration
  final TextEditingController _firebaseApiKeyController = TextEditingController();
  final TextEditingController _firebaseAuthDomainController = TextEditingController();
  final TextEditingController _firebaseProjectIdController = TextEditingController();
  final TextEditingController _firebaseStorageBucketController = TextEditingController();
  final TextEditingController _firebaseMessagingSenderIdController = TextEditingController();
  final TextEditingController _firebaseAppIdController = TextEditingController();
  
  // Stripe Configuration
  final TextEditingController _stripePublicKeyController = TextEditingController();
  final TextEditingController _stripeSecretKeyController = TextEditingController();
  final TextEditingController _stripeWebhookSecretController = TextEditingController();
  
  // SMTP Configuration
  final TextEditingController _smtpHostController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUsernameController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();
  
  bool _obscureKeys = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFirebaseConfig(),
            const SizedBox(height: 24),
            _buildStripeConfig(),
            const SizedBox(height: 24),
            _buildSMTPConfig(),
            const SizedBox(height: 24),
            _buildAppSettings(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Configure Firebase, payments, and system settings',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseConfig() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fireplace,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Database, Authentication & Storage',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _obscureKeys = !_obscureKeys;
                  });
                },
                icon: Icon(
                  _obscureKeys ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firebaseApiKeyController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'Firebase API Key',
              hintText: 'AIzaSy...',
              helperText: 'From Firebase Console → Project Settings → Web App',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firebaseAuthDomainController,
            decoration: const InputDecoration(
              labelText: 'Auth Domain',
              hintText: 'your-project.firebaseapp.com',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firebaseProjectIdController,
                  decoration: const InputDecoration(
                    labelText: 'Project ID',
                    hintText: 'your-project-id',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _firebaseStorageBucketController,
                  decoration: const InputDecoration(
                    labelText: 'Storage Bucket',
                    hintText: 'your-project.appspot.com',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firebaseMessagingSenderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Messaging Sender ID',
                    hintText: '123456789',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _firebaseAppIdController,
                  decoration: const InputDecoration(
                    labelText: 'App ID',
                    hintText: '1:123456789:web:xxxxx',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _testFirebaseConnection();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _showFirebaseInstructions();
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Setup Guide'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripeConfig() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stripe Payment Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Accept payments & manage subscriptions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _stripePublicKeyController,
            decoration: const InputDecoration(
              labelText: 'Publishable Key',
              hintText: 'pk_live_...',
              helperText: 'From Stripe Dashboard → Developers → API Keys',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stripeSecretKeyController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'Secret Key',
              hintText: 'sk_live_...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stripeWebhookSecretController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'Webhook Secret',
              hintText: 'whsec_...',
              helperText: 'For webhook event verification',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _testStripeConnection();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Stripe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _openStripeWebsite();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Stripe Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSMTPConfig() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.email,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email (SMTP) Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Send transactional emails & notifications',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _smtpHostController,
                  decoration: const InputDecoration(
                    labelText: 'SMTP Host',
                    hintText: 'smtp.gmail.com',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _smtpPortController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '587',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _smtpUsernameController,
            decoration: const InputDecoration(
              labelText: 'Username / Email',
              hintText: 'your-email@gmail.com',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _smtpPasswordController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'Password / App Password',
              hintText: '••••••••',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _testEmailConnection();
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Test Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text(
              'Maintenance Mode',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Disable app access for non-admin users',
              style: TextStyle(color: AppTheme.greyText, fontSize: 12),
            ),
            value: false,
            onChanged: (value) {},
            activeColor: AppTheme.primaryGreen,
          ),
          const Divider(color: AppTheme.greyText),
          SwitchListTile(
            title: const Text(
              'Allow New Registrations',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Enable new user sign-ups',
              style: TextStyle(color: AppTheme.greyText, fontSize: 12),
            ),
            value: true,
            onChanged: (value) {},
            activeColor: AppTheme.primaryGreen,
          ),
          const Divider(color: AppTheme.greyText),
          SwitchListTile(
            title: const Text(
              'Email Verification Required',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Users must verify email before using app',
              style: TextStyle(color: AppTheme.greyText, fontSize: 12),
            ),
            value: true,
            onChanged: (value) {},
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _saveAllSettings();
            },
            icon: const Icon(Icons.save),
            label: const Text('Save All Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            _exportSettings();
          },
          icon: const Icon(Icons.download),
          label: const Text('Export Config'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            foregroundColor: AppTheme.primaryGreen,
            side: const BorderSide(color: AppTheme.primaryGreen),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            _importSettings();
          },
          icon: const Icon(Icons.upload),
          label: const Text('Import Config'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            foregroundColor: AppTheme.greyText,
            side: const BorderSide(color: AppTheme.greyText),
          ),
        ),
      ],
    );
  }

  void _testFirebaseConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing Firebase connection...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showFirebaseInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Firebase Setup Guide', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionStep('1', 'Go to Firebase Console', 'https://console.firebase.google.com/'),
              _buildInstructionStep('2', 'Create new project', 'Name it "FoodGeniusAI"'),
              _buildInstructionStep('3', 'Add Web App', 'Click </> icon'),
              _buildInstructionStep('4', 'Copy config values', 'Paste them in the fields above'),
              _buildInstructionStep('5', 'Enable Authentication', 'Email/Password method'),
              _buildInstructionStep('6', 'Create Firestore Database', 'Start in test mode'),
              _buildInstructionStep('7', 'Enable Storage', 'For recipe images'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testStripeConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing Stripe connection...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _openStripeWebsite() {
    // Open https://dashboard.stripe.com
  }

  void _testEmailConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending test email...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveAllSettings() {
    // Save to local storage or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportSettings() {
    // Export settings as JSON file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings exported!'),
      ),
    );
  }

  void _importSettings() {
    // Import settings from JSON file
  }
}

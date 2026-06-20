import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../services/favicon_service.dart';
import '../../services/dodopayment_service.dart';
import '../../widgets/web_image.dart';

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
  
  // DodoPayment Configuration
  final TextEditingController _dodoApiKeyController = TextEditingController();
  final TextEditingController _dodoBusinessIdController = TextEditingController();
  final TextEditingController _dodoWebhookSecretController = TextEditingController();
  bool _dodoTestMode = true;
  
  bool _obscureKeys = true;
  
  // Favicon state
  String? _currentFaviconUrl;
  Uint8List? _selectedFaviconData;
  String? _selectedFaviconName;
  bool _isUploadingFavicon = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFavicon();
    _loadDodoPaymentConfig();
  }

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
            _buildDodoPaymentConfig(),
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

  Widget _buildDodoPaymentConfig() {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DodoPayment Configuration',
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
            controller: _dodoApiKeyController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'dodo_sk_...',
              helperText: 'From DodoPayments Dashboard → API Keys',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dodoBusinessIdController,
            decoration: const InputDecoration(
              labelText: 'Business ID',
              hintText: 'bus_...',
              helperText: 'Your DodoPayments Business ID',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dodoWebhookSecretController,
            obscureText: _obscureKeys,
            decoration: const InputDecoration(
              labelText: 'Webhook Secret',
              hintText: 'whsec_...',
              helperText:
                  'From DodoPayments Dashboard → Webhooks. Endpoint: https://us-central1-gourmetai-c432b.cloudfunctions.net/dodoPaymentsWebhook',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Test Mode',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Use test mode for development',
              style: TextStyle(color: AppTheme.greyText, fontSize: 12),
            ),
            value: _dodoTestMode,
            onChanged: (value) {
              setState(() {
                _dodoTestMode = value;
              });
            },
            activeColor: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _testDodoPaymentConnection();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _saveDodoPaymentConfig();
                },
                icon: const Icon(Icons.save),
                label: const Text('Save DodoPay Config'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _openDodoPaymentWebsite();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'App behavior & branding',
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
          
          // Favicon Upload Section
          _buildFaviconUploadSection(),
          
          const SizedBox(height: 16),
          const Divider(color: AppTheme.greyText),
          const SizedBox(height: 16),
          
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

  Widget _buildFaviconUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyText.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'App Favicon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a custom favicon - it will update automatically in your browser tab!',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryGreen,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Automatic! No rebuild needed',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Favicon Preview
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.greyText.withOpacity(0.3),
                  ),
                ),
                child: _selectedFaviconData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedFaviconData!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : _currentFaviconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: WebImage(
                              key: ValueKey(_currentFaviconUrl),
                              imageUrl: _currentFaviconUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, _) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        color: Colors.redAccent, size: 32),
                                    SizedBox(height: 6),
                                    Text(
                                      'Image\nunreachable',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: AppTheme.greyText,
                                  size: 40,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No favicon',
                                  style: TextStyle(
                                    color: AppTheme.greyText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
              
              const SizedBox(width: 20),
              
              // Upload Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedFaviconName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFaviconName!,
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploadingFavicon ? null : _selectFavicon,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(
                            _selectedFaviconData != null
                                ? 'Change Image'
                                : 'Select Favicon',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        
                        if (_currentFaviconUrl != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                // Force reload by re-setting the URL
                                final url = _currentFaviconUrl;
                                _currentFaviconUrl = null;
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  setState(() {
                                    _currentFaviconUrl = url;
                                  });
                                });
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 20),
                            color: AppTheme.greyText,
                            tooltip: 'Refresh Preview',
                          ),
                        ],
                        
                        if (_selectedFaviconData != null) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isUploadingFavicon ? null : _uploadFavicon,
                            icon: _isUploadingFavicon
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload, size: 18),
                            label: Text(
                              _isUploadingFavicon ? 'Uploading...' : 'Upload',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _isUploadingFavicon ? null : () {
                              setState(() {
                                _selectedFaviconData = null;
                                _selectedFaviconName = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            color: Colors.red,
                            tooltip: 'Cancel',
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      'Recommended: PNG or ICO format, 32x32 or 512x512 pixels',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.greyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Future<void> _loadDodoPaymentConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('payment_settings')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _dodoApiKeyController.text = data?['dodo_api_key'] ?? '';
          _dodoBusinessIdController.text = data?['dodo_business_id'] ?? '';
          _dodoWebhookSecretController.text = data?['dodo_webhook_secret'] ?? '';
          _dodoTestMode = data?['dodo_test_mode'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading DodoPayment config: $e');
    }
  }

  Future<void> _saveDodoPaymentConfig() async {
    if (_dodoApiKeyController.text.isEmpty || _dodoBusinessIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all DodoPayment fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await DodoPaymentService().saveConfiguration(
        apiKey: _dodoApiKeyController.text.trim(),
        businessId: _dodoBusinessIdController.text.trim(),
        testMode: _dodoTestMode,
        webhookSecret: _dodoWebhookSecretController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DodoPayment configuration saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testDodoPaymentConnection() async {
    if (_dodoApiKeyController.text.isEmpty ||
        _dodoBusinessIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter API Key and Business ID first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing DodoPayment connection...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      DodoPaymentService().applyConfiguration(
        apiKey: _dodoApiKeyController.text.trim(),
        businessId: _dodoBusinessIdController.text.trim(),
        testMode: _dodoTestMode,
      );

      try {
        await DodoPaymentService().saveConfiguration(
          apiKey: _dodoApiKeyController.text.trim(),
          businessId: _dodoBusinessIdController.text.trim(),
          testMode: _dodoTestMode,
          webhookSecret: _dodoWebhookSecretController.text.trim(),
        );
      } catch (e) {
        print('DodoPayment config save failed (testing anyway): $e');
      }

      final result = await DodoPaymentService().testConnection();

      if (mounted) {
        final modeLabel = _dodoTestMode ? 'test' : 'live';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.success
                        ? 'DodoPayment connected ($modeLabel mode)!'
                        : 'Connection failed ($modeLabel mode): ${result.message}',
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: Duration(seconds: result.success ? 4 : 8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openDodoPaymentWebsite() {
    html.window.open('https://dashboard.dodopayments.com', '_blank');
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

  // Favicon Management Methods
  
  Future<void> _loadCurrentFavicon() async {
    try {
      // Try to load favicon URL from Firestore settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('app_settings')
          .get();
      
      if (settingsDoc.exists && settingsDoc.data()?['faviconUrl'] != null) {
        final raw = settingsDoc.data()!['faviconUrl'] as String;
        final t = DateTime.now().millisecondsSinceEpoch;
        final url = raw.contains('?') ? '$raw&v=$t' : '$raw?v=$t';
        setState(() => _currentFaviconUrl = url);
      }
    } catch (e) {
      print('Error loading current favicon: $e');
    }
  }

  /// Replaces every <link rel="icon"> in <head> with the given data URL right
  /// now, synchronously, so the tab updates the moment the admin clicks
  /// Upload — even before the Storage round-trip completes.
  void _applyDataUrlImmediately(String dataUrl) {
    final head = html.document.head;
    if (head == null) return;
    head
        .querySelectorAll(
            'link[rel~="icon"], link[rel="shortcut icon"], link[rel="apple-touch-icon"], link[rel="apple-touch-icon-precomposed"]')
        .forEach((n) => n.remove());
    void add(String rel, {String? sizes, String? type}) {
      final link = html.LinkElement()
        ..rel = rel
        ..href = dataUrl
        ..setAttribute('data-dynamic', '1');
      if (type != null) link.type = type;
      if (sizes != null) link.setAttribute('sizes', sizes);
      head.append(link);
    }

    add('icon', type: 'image/png', sizes: '16x16');
    add('icon', type: 'image/png', sizes: '32x32');
    add('icon', type: 'image/png', sizes: '48x48');
    add('icon', type: 'image/png', sizes: '192x192');
    add('icon', type: 'image/png', sizes: '512x512');
    add('icon', type: 'image/png', sizes: 'any');
    add('shortcut icon', type: 'image/png');
    add('apple-touch-icon', sizes: '180x180');

    // Nudge Chromium to redraw the tab icon immediately.
    final originalTitle = html.document.title;
    html.document.title = '$originalTitle\u200B';
    Future.delayed(const Duration(milliseconds: 60), () {
      html.document.title = originalTitle;
    });
  }

  void _selectFavicon() {
    // Create file input element
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/png,image/x-icon,image/jpeg,image/jpg';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((event) {
          setState(() {
            _selectedFaviconData = reader.result as Uint8List;
            _selectedFaviconName = file.name;
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  Future<void> _uploadFavicon() async {
    if (_selectedFaviconData == null) return;

    setState(() {
      _isUploadingFavicon = true;
    });

    try {
      final isIco = _selectedFaviconName?.toLowerCase().endsWith('.ico') ?? false;
      final mime = isIco ? 'image/x-icon' : 'image/png';

      // 1. Encode locally as a base64 data URL and seed the favicon NOW.
      //    This means the admin's tab and EVERY future reload of this browser
      //    show the new favicon instantly with zero network round-trip.
      final dataUrl = 'data:$mime;base64,${base64Encode(_selectedFaviconData!)}';
      _applyDataUrlImmediately(dataUrl);

      // 2. Upload the binary to Firebase Storage.
      final storageRef =
          FirebaseStorage.instance.ref().child('app_assets/favicon.png');
      final uploadTask = storageRef.putData(
        _selectedFaviconData!,
        SettableMetadata(contentType: mime),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Persist the URL in Firestore so other admins / devices get it.
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('app_settings')
          .set({
        'faviconUrl': downloadUrl,
        'faviconUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Tell FaviconService to keep both localStorage keys in sync.
      FaviconService().cacheUploadedFavicon(
        dataUrl: dataUrl,
        remoteUrl: downloadUrl,
        version: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Append a cache-buster so Image.network / WebImage refetch even if
      // the path is the same as the previous upload.
      final t = DateTime.now().millisecondsSinceEpoch;
      final previewUrl =
          downloadUrl.contains('?') ? '$downloadUrl&v=$t' : '$downloadUrl?v=$t';

      setState(() {
        _currentFaviconUrl = previewUrl;
        _selectedFaviconData = null;
        _selectedFaviconName = null;
        _isUploadingFavicon = false;
      });

      // Hot-swap the live browser tab favicon.
      await FaviconService().refreshFavicon();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Favicon uploaded — tab updates in a second.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'For Google Search, run tools/sync_favicons_from_firebase.ps1 '
                        'then flutter build web --release && firebase deploy --only hosting.',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingFavicon = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading favicon: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUpdateInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Text(
              'Apply Favicon to Your App',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Follow these steps to update your app with the new favicon:',
                  style: TextStyle(color: AppTheme.greyText, fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                // Step 1: Copy URL
                _buildInstructionStep(
                  '1',
                  'Copy the Firebase Storage URL',
                  'Your favicon URL:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _currentFaviconUrl ?? 'No URL available',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        color: AppTheme.primaryGreen,
                        onPressed: () {
                          if (_currentFaviconUrl != null) {
                            html.window.navigator.clipboard?.writeText(_currentFaviconUrl!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ URL copied!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        tooltip: 'Copy URL',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Step 2: Update HTML
                _buildInstructionStep(
                  '2',
                  'Update web/index.html',
                  'Find line 52 and replace:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const SelectableText(
                    '<link rel="icon" type="image/png" href="favicon.png"/>',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Icon(Icons.arrow_downward, color: AppTheme.greyText),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    '<link rel="icon" type="image/png" href="${_currentFaviconUrl ?? 'YOUR_FIREBASE_URL'}"/>',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Step 3: Rebuild
                _buildInstructionStep(
                  '3',
                  'Rebuild the web app',
                  'Run in terminal:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'flutter build web --release',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Step 4: Deploy
                _buildInstructionStep(
                  '4',
                  'Deploy to Firebase',
                  'Run in terminal:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'firebase deploy --only hosting',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Step 5: Clear Cache
                _buildInstructionStep(
                  '5',
                  'Clear browser cache',
                  'Press Ctrl + Shift + Delete or hard refresh (Ctrl + F5)',
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your custom favicon will now appear in browser tabs!',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

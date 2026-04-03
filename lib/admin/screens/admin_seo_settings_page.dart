import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminSeoSettingsPage extends StatefulWidget {
  const AdminSeoSettingsPage({super.key});

  @override
  State<AdminSeoSettingsPage> createState() => _AdminSeoSettingsPageState();
}

class _AdminSeoSettingsPageState extends State<AdminSeoSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _metaTitleController = TextEditingController();
  final TextEditingController _metaDescriptionController = TextEditingController();
  final TextEditingController _metaKeywordsController = TextEditingController();
  final TextEditingController _ogTitleController = TextEditingController();
  final TextEditingController _ogDescriptionController = TextEditingController();
  final TextEditingController _ogImageController = TextEditingController();
  final TextEditingController _twitterHandleController = TextEditingController();
  final TextEditingController _googleAnalyticsIdController = TextEditingController();
  final TextEditingController _googleSearchConsoleController = TextEditingController();
  final TextEditingController _robotsTxtController = TextEditingController();
  final TextEditingController _sitemapUrlController = TextEditingController();
  final TextEditingController _canonicalUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSeoSettings();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    _metaKeywordsController.dispose();
    _ogTitleController.dispose();
    _ogDescriptionController.dispose();
    _ogImageController.dispose();
    _twitterHandleController.dispose();
    _googleAnalyticsIdController.dispose();
    _googleSearchConsoleController.dispose();
    _robotsTxtController.dispose();
    _sitemapUrlController.dispose();
    _canonicalUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSeoSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('seo_settings')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _siteNameController.text = data['siteName'] ?? '';
        _metaTitleController.text = data['metaTitle'] ?? '';
        _metaDescriptionController.text = data['metaDescription'] ?? '';
        _metaKeywordsController.text = data['metaKeywords'] ?? '';
        _ogTitleController.text = data['ogTitle'] ?? '';
        _ogDescriptionController.text = data['ogDescription'] ?? '';
        _ogImageController.text = data['ogImage'] ?? '';
        _twitterHandleController.text = data['twitterHandle'] ?? '';
        _googleAnalyticsIdController.text = data['googleAnalyticsId'] ?? '';
        _googleSearchConsoleController.text = data['googleSearchConsole'] ?? '';
        _robotsTxtController.text = data['robotsTxt'] ?? _getDefaultRobotsTxt();
        _sitemapUrlController.text = data['sitemapUrl'] ?? '';
        _canonicalUrlController.text = data['canonicalUrl'] ?? '';
      } else {
        _robotsTxtController.text = _getDefaultRobotsTxt();
      }
    } catch (e) {
      _showSnackBar('Error loading SEO settings: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSeoSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('seo_settings')
          .set({
        'siteName': _siteNameController.text.trim(),
        'metaTitle': _metaTitleController.text.trim(),
        'metaDescription': _metaDescriptionController.text.trim(),
        'metaKeywords': _metaKeywordsController.text.trim(),
        'ogTitle': _ogTitleController.text.trim(),
        'ogDescription': _ogDescriptionController.text.trim(),
        'ogImage': _ogImageController.text.trim(),
        'twitterHandle': _twitterHandleController.text.trim(),
        'googleAnalyticsId': _googleAnalyticsIdController.text.trim(),
        'googleSearchConsole': _googleSearchConsoleController.text.trim(),
        'robotsTxt': _robotsTxtController.text.trim(),
        'sitemapUrl': _sitemapUrlController.text.trim(),
        'canonicalUrl': _canonicalUrlController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('SEO settings saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving SEO settings: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getDefaultRobotsTxt() {
    return '''User-agent: *
Allow: /
Disallow: /admin
Disallow: /api

Sitemap: https://yourdomain.com/sitemap.xml''';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildBasicSeoSection(),
                const SizedBox(height: 24),
                _buildOpenGraphSection(),
                const SizedBox(height: 24),
                _buildTwitterSection(),
                const SizedBox(height: 24),
                _buildAnalyticsSection(),
                const SizedBox(height: 24),
                _buildTechnicalSeoSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
                Icons.search,
                color: AppTheme.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEO Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Optimize your app for search engines and social media',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicSeoSection() {
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
                  Icons.text_fields,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic SEO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Site name, title, description & keywords',
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
          TextFormField(
            controller: _siteNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Site Name',
              hintText: 'FoodGeniusAI',
              helperText: 'Your application name',
              prefixIcon: Icon(Icons.label, color: AppTheme.primaryGreen),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Site name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _metaTitleController,
            style: const TextStyle(color: Colors.white),
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Meta Title',
              hintText: 'AI-Powered Recipe Generator | FoodGeniusAI',
              helperText: 'Optimal length: 50-60 characters',
              prefixIcon: Icon(Icons.title, color: AppTheme.primaryGreen),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Meta title is required';
              }
              if (value.length > 60) {
                return 'Meta title should be 60 characters or less';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _metaDescriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Meta Description',
              hintText: 'Create delicious recipes with AI. Generate personalized meal plans...',
              helperText: 'Optimal length: 150-160 characters',
              prefixIcon: Icon(Icons.description, color: AppTheme.primaryGreen),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Meta description is required';
              }
              if (value.length > 160) {
                return 'Meta description should be 160 characters or less';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _metaKeywordsController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Meta Keywords',
              hintText: 'AI recipes, recipe generator, meal planning, cooking, food',
              helperText: 'Comma-separated keywords',
              prefixIcon: Icon(Icons.tag, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _canonicalUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Canonical URL',
              hintText: 'https://yourdomain.com',
              helperText: 'The primary domain URL for your site',
              prefixIcon: Icon(Icons.link, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenGraphSection() {
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
                  Icons.share,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Graph (Facebook)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Social media sharing preview',
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
          TextFormField(
            controller: _ogTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'OG Title',
              hintText: 'FoodGeniusAI - AI Recipe Generator',
              helperText: 'Title shown when shared on Facebook/LinkedIn',
              prefixIcon: Icon(Icons.title, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ogDescriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'OG Description',
              hintText: 'Create amazing recipes with the power of AI',
              helperText: 'Description shown when shared',
              prefixIcon: Icon(Icons.description, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ogImageController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'OG Image URL',
              hintText: 'https://yourdomain.com/og-image.jpg',
              helperText: 'Image shown when shared (recommended: 1200x630px)',
              prefixIcon: Icon(Icons.image, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterSection() {
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
                  color: Colors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.lightBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Twitter / X Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Twitter card and handle',
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
          TextFormField(
            controller: _twitterHandleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Twitter Handle',
              hintText: '@foodgeniusai',
              helperText: 'Your Twitter/X username',
              prefixIcon: Icon(Icons.alternate_email, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
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
                  Icons.analytics,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics & Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Google Analytics and Search Console',
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
          TextFormField(
            controller: _googleAnalyticsIdController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Google Analytics ID',
              hintText: 'G-XXXXXXXXXX or UA-XXXXXXXXX',
              helperText: 'From Google Analytics dashboard',
              prefixIcon: Icon(Icons.bar_chart, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _googleSearchConsoleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Google Search Console Verification',
              hintText: 'Verification code from Search Console',
              helperText: 'Meta tag content value',
              prefixIcon: Icon(Icons.verified, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSeoSection() {
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
                  Icons.code,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technical SEO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Robots.txt and Sitemap',
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
          TextFormField(
            controller: _sitemapUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Sitemap URL',
              hintText: 'https://yourdomain.com/sitemap.xml',
              helperText: 'URL to your sitemap file',
              prefixIcon: Icon(Icons.map, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _robotsTxtController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'robots.txt Content',
              helperText: 'Define crawling rules for search engines',
              prefixIcon: Icon(Icons.smart_toy, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These settings will be used to generate meta tags in your HTML. After saving, you may need to rebuild and redeploy your app.',
                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
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
            onPressed: _isSaving ? null : _saveSeoSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save SEO Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: AppTheme.primaryGreen,
              disabledBackgroundColor: AppTheme.greyText,
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _isLoading || _isSaving ? null : _loadSeoSettings,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            foregroundColor: AppTheme.greyText,
            side: const BorderSide(color: AppTheme.greyText),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            _showPreviewDialog();
          },
          icon: const Icon(Icons.preview),
          label: const Text('Preview'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            foregroundColor: AppTheme.primaryGreen,
            side: const BorderSide(color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'SEO Preview',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Google Search Result Preview',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _metaTitleController.text.isNotEmpty
                            ? _metaTitleController.text
                            : 'Your Meta Title',
                        style: const TextStyle(
                          color: Color(0xFF1a0dab),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _canonicalUrlController.text.isNotEmpty
                            ? _canonicalUrlController.text
                            : 'https://yourdomain.com',
                        style: const TextStyle(
                          color: Color(0xFF006621),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _metaDescriptionController.text.isNotEmpty
                            ? _metaDescriptionController.text
                            : 'Your meta description will appear here...',
                        style: const TextStyle(
                          color: Color(0xFF545454),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Facebook Share Preview',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_ogImageController.text.isNotEmpty)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 48, color: Colors.grey),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _canonicalUrlController.text.isNotEmpty
                                  ? _canonicalUrlController.text.toUpperCase()
                                  : 'YOURDOMAIN.COM',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ogTitleController.text.isNotEmpty
                                  ? _ogTitleController.text
                                  : 'Your OG Title',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ogDescriptionController.text.isNotEmpty
                                  ? _ogDescriptionController.text
                                  : 'Your OG description will appear here...',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

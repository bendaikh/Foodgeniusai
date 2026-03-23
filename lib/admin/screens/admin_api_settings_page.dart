import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_settings_service.dart';
import '../../services/openai_service.dart';
import '../../models/ai_settings_model.dart';

class AdminApiSettingsPage extends StatefulWidget {
  const AdminApiSettingsPage({super.key});

  @override
  State<AdminApiSettingsPage> createState() => _AdminApiSettingsPageState();
}

class _AdminApiSettingsPageState extends State<AdminApiSettingsPage> {
  final AISettingsService _settingsService = AISettingsService();
  final TextEditingController _openaiKeyController = TextEditingController();
  final TextEditingController _openaiModelController =
      TextEditingController(text: 'gpt-4o-mini');
  final TextEditingController _maxTokensController =
      TextEditingController(text: '2000');
  final TextEditingController _temperatureController =
      TextEditingController(text: '0.7');
  
  bool _obscureApiKey = true;
  String _selectedProvider = 'OpenAI';
  String _selectedImageProvider = 'DALL-E 3';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _selectedProvider = settings.provider;
        _openaiKeyController.text = settings.openaiApiKey ?? '';
        _openaiModelController.text = settings.openaiModel ?? 'gpt-4';
        _maxTokensController.text = settings.maxTokens?.toString() ?? '2000';
        _temperatureController.text = settings.temperature?.toString() ?? '0.7';
        _selectedImageProvider = settings.imageProvider ?? 'DALL-E 3';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final settings = AISettingsModel(
        provider: _selectedProvider,
        openaiApiKey: _openaiKeyController.text.trim(),
        openaiModel: _openaiModelController.text.trim(),
        maxTokens: int.tryParse(_maxTokensController.text) ?? 2000,
        temperature: double.tryParse(_temperatureController.text) ?? 0.7,
        imageProvider: _selectedImageProvider,
      );

      await _settingsService.saveSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    if (_openaiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      // Create temporary settings for testing
      final testSettings = AISettingsModel(
        provider: _selectedProvider,
        openaiApiKey: _openaiKeyController.text.trim(),
        openaiModel: _openaiModelController.text.trim().isEmpty 
            ? 'gpt-4o-mini' 
            : _openaiModelController.text.trim(),
        maxTokens: 1500, // Enough for a simple test recipe
        temperature: 0.7,
        imageProvider: _selectedImageProvider,
      );

      final openaiService = OpenAIService(testSettings);

      // Make a simple test request (no recipe generation)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testing connection to OpenAI...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final testResult = await openaiService.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Connection Successful!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('API Key is valid and working'),
                Text('Model: ${testSettings.openaiModel}'),
                Text('Response: $testResult'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Incorrect API key')) {
          errorMessage = 'Invalid API key. Please check your OpenAI API key.';
        } else if (errorMessage.contains('insufficient_quota')) {
          errorMessage = 'Your OpenAI account has insufficient credits. Please add credits to your account.';
        } else if (errorMessage.contains('rate_limit')) {
          errorMessage = 'Rate limit exceeded. Please try again in a moment.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(errorMessage),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
    _openaiModelController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildApiProvider(),
            const SizedBox(height: 24),
            _buildOpenAISettings(),
            const SizedBox(height: 24),
            _buildImageGeneration(),
            const SizedBox(height: 24),
            _buildRateLimits(),
            const SizedBox(height: 32),
            _buildSaveButton(),
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
          'API Settings',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Configure AI providers and API keys',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildApiProvider() {
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
            'AI Provider',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProviderCard(
                  'OpenAI',
                  'GPT-4 & DALL-E',
                  Icons.psychology,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProviderCard(
                  'Anthropic',
                  'Claude AI',
                  Icons.smart_toy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProviderCard(
                  'Google',
                  'Gemini Pro',
                  Icons.lightbulb,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(String name, String description, IconData icon) {
    final isSelected = _selectedProvider == name;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedProvider = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.primaryGreen.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.greyText,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAISettings() {
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
              const Icon(Icons.api, color: AppTheme.primaryGreen),
              const SizedBox(width: 12),
              const Text(
                'OpenAI Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _openaiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.key, color: AppTheme.greyText),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.greyText,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Test Connection'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openaiModelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4',
                    prefixIcon: Icon(Icons.psychology, color: AppTheme.greyText),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxTokensController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Tokens',
                    hintText: '2000',
                    prefixIcon: Icon(Icons.token, color: AppTheme.greyText),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _temperatureController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Temperature',
                    hintText: '0.7',
                    prefixIcon: Icon(Icons.thermostat, color: AppTheme.greyText),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGeneration() {
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
          const Row(
            children: [
              Icon(Icons.image, color: AppTheme.primaryGreen),
              SizedBox(width: 12),
              Text(
                'Image Generation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildImageProviderOption(
                  'DALL-E 3',
                  'High quality, 1024x1024',
                  '\$0.040 per image',
                  _selectedImageProvider == 'DALL-E 3',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageProviderOption(
                  'DALL-E 2',
                  'Standard quality, 512x512',
                  '\$0.020 per image',
                  _selectedImageProvider == 'DALL-E 2',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageProviderOption(
                  'Stable Diffusion',
                  'Custom models',
                  '\$0.010 per image',
                  _selectedImageProvider == 'Stable Diffusion',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageProviderOption(
    String name,
    String specs,
    String cost,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedImageProvider = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            specs,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cost,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRateLimits() {
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
          const Row(
            children: [
              Icon(Icons.speed, color: AppTheme.primaryGreen),
              SizedBox(width: 12),
              Text(
                'Rate Limits & Usage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildUsageCard(
                  'Requests Today',
                  '3,847',
                  '/ 10,000 limit',
                  0.38,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageCard(
                  'Tokens Used',
                  '2.4M',
                  '/ 5M limit',
                  0.48,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageCard(
                  'Cost (Today)',
                  '\$127.50',
                  '/ \$500 budget',
                  0.26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, String value, String limit, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            limit,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.greyText.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.red : AppTheme.primaryGreen,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Settings'),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: (_isSaving || _isTesting) ? null : _testApiConnection,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            side: const BorderSide(color: AppTheme.primaryGreen),
          ),
          child: _isTesting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                )
              : const Text(
                  'Test API Connection',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
        ),
      ],
    );
  }
}

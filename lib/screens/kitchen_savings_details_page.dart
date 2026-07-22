import 'package:flutter/material.dart';

import '../services/voice_guide_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_audio_button.dart';
import '../widgets/voice_guide_route_aware.dart';

/// Lightweight testing destination for Kitchen Savings.
///
/// Savings calculations are intentionally deferred until tracking data exists.
class KitchenSavingsDetailsPage extends StatefulWidget {
  const KitchenSavingsDetailsPage({super.key});

  @override
  State<KitchenSavingsDetailsPage> createState() =>
      _KitchenSavingsDetailsPageState();
}

class _KitchenSavingsDetailsPageState extends State<KitchenSavingsDetailsPage>
    with VoiceGuideRouteAware {
  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.kitchenSavings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initVoiceGuide();
  }

  @override
  void dispose() {
    disposeVoiceGuide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kitchen Savings'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: PremiumAudioButton(size: 36, iconSize: 18)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ESTIMATED SAVINGS',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'Saved this month',
                  style: TextStyle(color: AppTheme.greyText, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '\$0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Keep using Scan Fridge and Kitchen Treasures. Detailed savings tracking will appear here as the feature is developed.',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 14,
                    height: 1.5,
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

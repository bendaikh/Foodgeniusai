import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class CookingAnimation extends StatefulWidget {
  final String? message;
  
  const CookingAnimation({
    super.key,
    this.message,
  });

  @override
  State<CookingAnimation> createState() => _CookingAnimationState();
}

class _CookingAnimationState extends State<CookingAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie cooking animation from local asset
          // To get this animation:
          // 1. Go to https://lottiefiles.com/free-animation/cooking-loop-animation-97EHuJ35sz
          // 2. Click Download > Lottie JSON
          // 3. Save to assets/animations/cooking.json
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.asset(
              'assets/animations/cooking.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              frameRate: FrameRate.max,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Lottie animation not found. Please download from LottieFiles.');
                return _buildFallbackAnimation();
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Loading message
          Text(
            widget.message ?? 'Cooking up something delicious...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Animated progress dots
          _buildProgressDots(),
        ],
      ),
    );
  }

  Widget _buildFallbackAnimation() {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.restaurant,
          size: 50,
          color: AppTheme.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final progress = (_dotsController.value + delay) % 1;
            final opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: 0.3 + (opacity * 0.7),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _potController;
  late AnimationController _spoonController;
  late AnimationController _steamController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    // Pot shaking animation
    _potController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Spoon stirring animation
    _spoonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    // Steam rising animation
    _steamController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _potController.dispose();
    _spoonController.dispose();
    _steamController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated cooking scene
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sparkles in background
                _buildSparkles(),
                
                // Steam clouds
                _buildSteam(),
                
                // Cooking pot
                _buildPot(),
                
                // Stirring spoon
                _buildSpoon(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
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
          
          // Progress dots
          _buildProgressDots(),
        ],
      ),
    );
  }

  Widget _buildPot() {
    return AnimatedBuilder(
      animation: _potController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_potController.value * 4 - 2, 0),
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pot handles
                Positioned(
                  left: -10,
                  top: 20,
                  child: Container(
                    width: 15,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: 20,
                  child: Container(
                    width: 15,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                // Bubbles inside pot
                Positioned(
                  left: 30,
                  top: 25,
                  child: _buildBubble(8),
                ),
                Positioned(
                  right: 35,
                  top: 30,
                  child: _buildBubble(6),
                ),
                Positioned(
                  left: 50,
                  top: 20,
                  child: _buildBubble(7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubble(double size) {
    return AnimatedBuilder(
      animation: _potController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_potController.value * 0.4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpoon() {
    return AnimatedBuilder(
      animation: _spoonController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spoonController.value * 2 * 3.14159,
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 20,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSteam() {
    return AnimatedBuilder(
      animation: _steamController,
      builder: (context, child) {
        return Positioned(
          top: -60 * _steamController.value,
          child: Opacity(
            opacity: 1 - _steamController.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSteamCloud(-10),
                const SizedBox(width: 15),
                _buildSteamCloud(5),
                const SizedBox(width: 15),
                _buildSteamCloud(0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSteamCloud(double offset) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Stack(
          children: [
            _buildSparkle(20, 30, _sparkleController.value),
            _buildSparkle(140, 50, (_sparkleController.value + 0.3) % 1),
            _buildSparkle(60, 120, (_sparkleController.value + 0.6) % 1),
            _buildSparkle(130, 140, (_sparkleController.value + 0.8) % 1),
          ],
        );
      },
    );
  }

  Widget _buildSparkle(double left, double top, double progress) {
    final opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: Icon(
          Icons.star,
          color: AppTheme.primaryGreen,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return AnimatedBuilder(
      animation: _spoonController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final progress = (_spoonController.value + delay) % 1;
            final opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
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

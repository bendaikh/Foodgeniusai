import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

/// First-launch onboarding. Calls [onFinished] after the final CTA
/// (onboarding is already marked complete before the callback).
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page < 2) {
      _pageController.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeFlow() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    await OnboardingService.instance.markCompleted();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.15,
            colors: [
              Color(0xFF0F2438),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _OnboardingPersonalizedPage(),
                    _OnboardingScanPage(),
                    _OnboardingOverviewPage(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset * 0.25),
                child: Column(
                  children: [
                    _PageDots(count: 3, index: _page),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _finishing
                            ? null
                            : () {
                                if (_page < 2) {
                                  _goNext();
                                } else {
                                  _completeFlow();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.darkBackground,
                          disabledBackgroundColor:
                              AppTheme.primaryGreen.withValues(alpha: 0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: Text(
                          _page < 2 ? 'Continue' : 'Start Cooking Smarter',
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
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 1 — Personalized recipes
// ---------------------------------------------------------------------------

class _OnboardingPersonalizedPage extends StatelessWidget {
  const _OnboardingPersonalizedPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingScaffold(
      headline: 'Recipes Made Just for You',
      body:
          'Tell us what you’re craving and get a complete recipe with ingredients, steps and nutrition.',
      visual: _PersonalizedRecipeVisual(),
    );
  }
}

class _PersonalizedRecipeVisual extends StatelessWidget {
  const _PersonalizedRecipeVisual();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: mathMin(constraints.maxHeight, 340),
          width: w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: w * 0.72,
                height: w * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: mathMin(w * 0.86, 320),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/onboarding/herb_crusted_salmon_bowl.png',
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.15),
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Just for you',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Herb-Crusted Salmon Bowl',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(label: '25 min'),
                              _InfoChip(label: 'High Protein'),
                              _InfoChip(label: '520 kcal'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

double mathMin(double a, double b) => a < b ? a : b;

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 2 — Fridge scan / Kitchen Treasures
// ---------------------------------------------------------------------------

class _OnboardingScanPage extends StatelessWidget {
  const _OnboardingScanPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingScaffold(
      headline: 'Turn What You Have Into Dinner',
      body:
          'Scan your fridge, discover what you can cook, waste less food and save money.',
      visual: _ScanFridgeVisual(),
      footerNote: 'Save more. Waste less. Cook better.',
    );
  }
}

class _ScanFridgeVisual extends StatelessWidget {
  const _ScanFridgeVisual();

  static const List<(String, IconData, String?)> _ingredients = [
    (
      'Tomato',
      Icons.eco_rounded,
      'assets/onboarding/ingredients/tomato.png',
    ),
    (
      'Chicken',
      Icons.set_meal_rounded,
      'assets/onboarding/ingredients/chicken.png',
    ),
    (
      'Avocado',
      Icons.spa_rounded,
      'assets/onboarding/ingredients/avocado.png',
    ),
    (
      'Eggs',
      Icons.egg_alt_rounded,
      'assets/onboarding/ingredients/eggs.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: mathMin(constraints.maxHeight, 360),
          width: constraints.maxWidth,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ..._scanCorners(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                        child: Column(
                          children: [
                            Text(
                              'SCANNING INGREDIENTS',
                              style: TextStyle(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.4,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (final item in _ingredients)
                                    _IngredientTile(
                                      label: item.$1,
                                      icon: item.$2,
                                      imageAsset: item.$3,
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
              const SizedBox(height: 14),
              Icon(
                Icons.arrow_downward_rounded,
                color: AppTheme.primaryGreen.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.18),
                      AppTheme.cardBackground,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creamy Avocado Chicken',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ready from your fridge',
                            style: TextStyle(
                              color: AppTheme.greyText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _scanCorners() {
    const inset = 10.0;
    Widget corner(Alignment a, bool top, bool left) {
      return Align(
        alignment: a,
        child: Padding(
          padding: const EdgeInsets.all(inset),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(
              painter: _CornerPainter(
                color: AppTheme.primaryGreen,
                top: top,
                left: left,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, true, true),
      corner(Alignment.topRight, true, false),
      corner(Alignment.bottomLeft, false, true),
      corner(Alignment.bottomRight, false, false),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    required this.top,
    required this.left,
  });

  final Color color;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) {
      path
        ..moveTo(0, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0);
    } else if (top && !left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height);
    } else if (!top && left) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.label,
    required this.icon,
    this.imageAsset,
  });

  final String label;
  final IconData icon;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          if (imageAsset != null)
            SizedBox(
              width: 34,
              height: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // The studio shots leave the food small inside a large black
                // frame, so zoom into the subject to make it clearly visible.
                child: Transform.scale(
                  scale: 1.35,
                  child: Image.asset(
                    imageAsset!,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.1),
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            )
          else
            Icon(icon, color: AppTheme.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 3 — Complete kitchen assistant
// ---------------------------------------------------------------------------

class _OnboardingOverviewPage extends StatelessWidget {
  const _OnboardingOverviewPage();

  static const _benefits = [
    (
      'Personalized Recipes',
      'assets/onboarding/features/personalized_recipes.png',
    ),
    (
      'Dietary Preferences',
      'assets/onboarding/features/dietary_preferences.png',
    ),
    (
      'Fridge Scanning',
      'assets/onboarding/features/fridge_scanning.png',
    ),
    (
      'Save Your Favorites',
      'assets/onboarding/features/save_favorites.png',
    ),
    (
      'Less Food Waste',
      'assets/onboarding/features/less_food_waste.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      headline: 'Your Smarter Kitchen Starts Here',
      body:
          'Everything you need to cook smarter, personalize your meals and make the most of your ingredients.',
      visual: Column(
        children: [
          for (var i = 0; i < _benefits.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _BenefitRow(
              label: _benefits[i].$1,
              imageAsset: _benefits[i].$2,
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label, required this.imageAsset});

  final String label;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.check_rounded,
            color: AppTheme.primaryGreen.withValues(alpha: 0.9),
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared layout
// ---------------------------------------------------------------------------

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.headline,
    required this.body,
    required this.visual,
    this.footerNote,
  });

  final String headline;
  final String body;
  final Widget visual;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'FoodGeniusAI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryGreen.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: Center(child: visual)),
          const SizedBox(height: 20),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.greyText,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (footerNote != null) ...[
            const SizedBox(height: 14),
            Text(
              footerNote!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

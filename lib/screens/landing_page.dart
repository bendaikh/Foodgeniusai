import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/audio_settings_service.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/premium_audio_button.dart';
import 'user_auth_page.dart';
import 'recipe_form_page.dart';
import 'user_account_page.dart';
import 'kitchen_treasures_page.dart';

class LandingPage extends StatefulWidget {
  /// When false, hides the top Profile / login shortcut (used inside MainShell).
  final bool showTopProfileShortcut;
  final double bottomContentInset;

  const LandingPage({
    super.key,
    this.showTopProfileShortcut = true,
    this.bottomContentInset = 0,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  bool _isHoveringRecipe = false;
  bool _isHoveringKitchen = false;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstLaunchVoicePrompt();
    });
  }

  Future<void> _maybeShowFirstLaunchVoicePrompt() async {
    final audio = AudioSettingsService.instance;
    if (!audio.isReady || !audio.shouldShowFirstLaunchVoicePrompt) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.primaryGreen.withValues(alpha: 0.28),
            ),
          ),
          title: const Text(
            '🎤 Enable Voice Guidance?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Hear short voice explanations while using FoodGeniusAI.\n'
            'You can change this anytime from the speaker icon in the top-right corner.',
            style: TextStyle(
              color: AppTheme.greyText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await audio.completeFirstLaunchVoicePrompt(enable: true);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Enable Voice Guidance'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await audio.completeFirstLaunchVoicePrompt(enable: false);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Not Now',
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleStartCreating(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeFormPage()),
    );
  }

  void _handleKitchenTreasures(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KitchenTreasuresPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;

    double horizontalPadding;
    double verticalPadding;

    if (isMobile) {
      horizontalPadding = 20.0;
      verticalPadding = 12.0;
    } else if (isTablet) {
      horizontalPadding = 48.0;
      verticalPadding = 28.0;
    } else {
      horizontalPadding = screenWidth * 0.08;
      verticalPadding = 40.0;
    }

    // With extendBody, content draws under the fixed bottom nav. Reserve the
    // complete bar/notch footprint, a comfortable trailing gap, and the device
    // safe area so the final card can scroll fully above navigation.
    const homeNavTrailingGap = 32.0;
    final shellNavClearance =
        widget.bottomContentInset > 0
            ? FloatingBottomNavBar.layoutHeight + homeNavTrailingGap
            : 0.0;
    final shellBottomSafeArea =
        widget.bottomContentInset > 0
            ? MediaQuery.viewPaddingOf(context).bottom
            : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeAtmosphereBackground(),
          SafeArea(
            bottom: widget.bottomContentInset <= 0,
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding + shellNavClearance + shellBottomSafeArea,
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    SizedBox(height: isMobile ? 8 : 16),
                    _buildTitle(isMobile),
                    SizedBox(height: isMobile ? 12 : 20),
                    _buildSubtitle(isMobile),
                    SizedBox(height: isMobile ? 28 : 44),
                    _buildOptions(context, isMobile),
                    SizedBox(height: isMobile ? 28 : 44),
                    _buildFooter(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authService = AuthService();
    final user = authService.currentUser;
    final showProfile = widget.showTopProfileShortcut;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProfile && !isMobile) ...[
            const TextButton(
              onPressed: null,
              child: Text('Home', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.wb_sunny_outlined, color: Colors.amber),
            ),
            const SizedBox(width: 8),
          ],
          const PremiumAudioButton(size: 40, iconSize: 20, pulse: true),
          if (showProfile) ...[
            const SizedBox(width: 4),
            if (user != null)
              _buildUserMenu(context, user, isMobile)
            else
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserAuthPage(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryGreen,
                  size: isMobile ? 20 : 24,
                ),
                tooltip: 'Login',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, User user, bool isMobile) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        String displayName = 'User';

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = data?['name'] ?? user.email?.split('@')[0] ?? 'User';
        } else {
          displayName = user.email?.split('@')[0] ?? 'User';
        }

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                  size: isMobile ? 16 : 20,
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryGreen,
                  size: isMobile ? 16 : 20,
                ),
              ],
            ),
          ),
          itemBuilder:
              (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppTheme.primaryGreen,
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Text('My Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 12),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
          onSelected: (value) async {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserAccountPage(),
                ),
              );
            } else if (value == 'logout') {
              await AuthService().signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildTitle(bool isMobile) {
    final titleSize = isMobile ? 24.0 : 38.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.28),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AI-POWERED EXCELLENCE',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 14 : 22),
        Text(
          'Elevate Your',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Culinary Vision',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            height: 1.12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return Text(
      'Create personalized recipes or turn the ingredients you already have into delicious meals.',
      style: TextStyle(
        fontSize: isMobile ? 13 : 16,
        color: AppTheme.greyText,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOptions(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: _buildOptionCard(
              context,
              icon: Icons.restaurant_menu_rounded,
              title: 'Generate Recipe',
              description:
                  'AI-crafted recipes based on your specific cravings and dietary needs.',
              buttonText: 'Start Creating',
              buttonIcon: Icons.auto_awesome_rounded,
              onPressed: () => _handleStartCreating(context),
              isMobile: true,
              isHovering: _isHoveringRecipe,
              onHoverChange:
                  (hovering) => setState(() => _isHoveringRecipe = hovering),
            ),
          ),
          const SizedBox(height: 14),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _buildOptionCard(
              context,
              icon: Icons.kitchen_rounded,
              title: 'Kitchen Treasures',
              description:
                  'Turn your available ingredients into gourmet masterpieces.',
              buttonText: 'Find Magic',
              buttonIcon: Icons.inventory_2_outlined,
              onPressed: () => _handleKitchenTreasures(context),
              isMobile: true,
              isHovering: _isHoveringKitchen,
              onHoverChange:
                  (hovering) => setState(() => _isHoveringKitchen = hovering),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: _buildOptionCard(
              context,
              icon: Icons.restaurant_menu_rounded,
              title: 'Generate Recipe',
              description:
                  'AI-crafted recipes based on your specific cravings and dietary needs.',
              buttonText: 'Start Creating',
              buttonIcon: Icons.auto_awesome_rounded,
              onPressed: () => _handleStartCreating(context),
              isMobile: false,
              isHovering: _isHoveringRecipe,
              onHoverChange:
                  (hovering) => setState(() => _isHoveringRecipe = hovering),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _buildOptionCard(
              context,
              icon: Icons.kitchen_rounded,
              title: 'Kitchen Treasures',
              description:
                  'Turn your available ingredients into gourmet masterpieces.',
              buttonText: 'Find Magic',
              buttonIcon: Icons.inventory_2_outlined,
              onPressed: () => _handleKitchenTreasures(context),
              isMobile: false,
              isHovering: _isHoveringKitchen,
              onHoverChange:
                  (hovering) => setState(() => _isHoveringKitchen = hovering),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
    required bool isMobile,
    required bool isHovering,
    required ValueChanged<bool> onHoverChange,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(20));

    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isHovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isHovering ? 0.28 : 0.18),
              blurRadius: isHovering ? 18 : 12,
              offset: Offset(0, isHovering ? 8 : 4),
            ),
            if (isHovering)
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color:
                  isHovering
                      ? AppTheme.primaryGreen.withValues(alpha: 0.55)
                      : AppTheme.primaryGreen.withValues(alpha: 0.16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            splashColor: AppTheme.primaryGreen.withValues(alpha: 0.10),
            highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18 : 26,
                isMobile ? 12 : 17,
                isMobile ? 18 : 26,
                isMobile ? 10 : 15,
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    scale: isHovering ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      icon,
                      size: isMobile ? 36 : 48,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 17),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: AppTheme.greyText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 14 : 16),
                  _PolishedActionButton(
                    label: buttonText,
                    icon: buttonIcon,
                    onPressed: onPressed,
                    emphasized: isHovering,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    const carouselItems = [
      _InsightData(
        icon: Icons.local_fire_department_rounded,
        label: 'Trending',
        value: 'Truffle Infusion',
      ),
      _InsightData(
        icon: Icons.insights_rounded,
        label: 'Taste Match',
        value: '98% Accuracy',
      ),
      _InsightData(
        icon: Icons.restaurant_rounded,
        label: 'Chef Tip',
        value: 'Searing Mastery',
      ),
      _InsightData(
        icon: Icons.favorite_rounded,
        label: 'AI Nutrition',
        value: 'Balanced & Healthy',
      ),
      _InsightData(
        icon: Icons.star_rounded,
        label: 'Smart Pick',
        value: 'Perfect for Tonight',
      ),
    ];

    if (isMobile) {
      return const _InsightCarousel(items: carouselItems);
    }

    final desktopItems = carouselItems.take(3).toList(growable: false);
    return Row(
      children: [
        for (var i = 0; i < desktopItems.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: _InsightCard(data: desktopItems[i])),
        ],
      ],
    );
  }
}

class _PolishedActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  const _PolishedActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.emphasized,
  });

  @override
  State<_PolishedActionButton> createState() => _PolishedActionButtonState();
}

class _PolishedActionButtonState extends State<_PolishedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : (widget.emphasized ? 1.03 : 1.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 16, color: AppTheme.darkBackground),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightData {
  final IconData icon;
  final String label;
  final String value;

  const _InsightData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightData data;

  const _InsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 16, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    height: 1.2,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCarousel extends StatefulWidget {
  final List<_InsightData> items;

  const _InsightCarousel({required this.items});

  @override
  State<_InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends State<_InsightCarousel> {
  static const int _virtualCount = 10000;
  static const Duration _autoSlideInterval = Duration(milliseconds: 3500);
  static const Duration _slideDuration = Duration(milliseconds: 450);
  static const double _carouselHeight = 76;
  static const double _viewportFraction = 0.93;

  late final PageController _pageController;
  late final int _initialPage;
  late final ValueNotifier<int> _activeIndex;
  Timer? _autoSlideTimer;
  bool _userInteracting = false;

  int get _itemCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    _initialPage = (_virtualCount ~/ 2) - ((_virtualCount ~/ 2) % _itemCount);
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: _viewportFraction,
    );
    _activeIndex = ValueNotifier<int>(0);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _stopAutoSlide();
    _activeIndex.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _stopAutoSlide();
    if (_itemCount <= 1) return;
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      if (!mounted || _userInteracting || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _onInteractionStart() {
    if (_userInteracting) return;
    _userInteracting = true;
    _stopAutoSlide();
  }

  void _onInteractionEnd() {
    if (!_userInteracting) return;
    _userInteracting = false;
    if (!mounted) return;
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _carouselHeight,
          width: double.infinity,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _onInteractionStart();
              } else if (notification is ScrollEndNotification) {
                _onInteractionEnd();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _virtualCount,
              padEnds: true,
              clipBehavior: Clip.hardEdge,
              allowImplicitScrolling: false,
              onPageChanged: (page) {
                final index = page % _itemCount;
                if (_activeIndex.value != index) {
                  _activeIndex.value = index;
                }
              },
              itemBuilder: (context, index) {
                final item = widget.items[index % _itemCount];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _InsightCard(data: item),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<int>(
          valueListenable: _activeIndex,
          builder: (context, activeIndex, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_itemCount, (index) {
                final isActive = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? AppTheme.primaryGreen
                            : AppTheme.primaryGreen.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Fixed, non-scrolling atmosphere layer for the Home Screen only.
class _HomeAtmosphereBackground extends StatelessWidget {
  const _HomeAtmosphereBackground();

  static const String _assetPath =
      'assets/backgrounds/home_cooking_atmosphere.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size.width * dpr * 0.65).round().clamp(320, 1080);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppTheme.darkBackground),
            ColoredBox(color: const Color(0xFF07121D).withValues(alpha: 0.85)),
            Opacity(
              opacity: 0.10,
              child: Transform.scale(
                scale: 1.25,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 45,
                    sigmaY: 45,
                    tileMode: TileMode.clamp,
                  ),
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: size.width,
                    height: size.height,
                    filterQuality: FilterQuality.low,
                    cacheWidth: cacheWidth,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00050B14),
                    Color(0x99050B14),
                    Color(0xF2050B14),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

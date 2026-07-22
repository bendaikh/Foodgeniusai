import 'package:flutter/material.dart';

import '../navigation/voice_guide_route_observer.dart';
import '../theme/app_theme.dart';
import '../services/voice_guide_service.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import 'landing_page.dart';
import 'my_creations_page.dart';
import 'user_account_page.dart';

/// App-wide shell with an edge-attached bottom navigation bar.
class MainShellPage extends StatefulWidget {
  final int initialIndex;

  static const int homeTab = 0;
  static const int myRecipesTab = 1;
  static const int savedTab = 2;
  static const int profileTab = 3;

  /// Trailing scroll padding so the last item clears above the nav.
  static const double contentBottomInset = 16;

  const MainShellPage({super.key, this.initialIndex = homeTab});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with RouteAware {
  late int _currentIndex;
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      MainShellPage.homeTab,
      MainShellPage.profileTab,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VoiceGuideService.instance.enterScreen(
        _screenForIndex(_currentIndex),
        owner: this,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_routeSubscribed && route is PageRoute) {
      voiceGuideRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      voiceGuideRouteObserver.unsubscribe(this);
    }
    VoiceGuideService.instance.leaveScreen(
      _screenForIndex(_currentIndex),
      owner: this,
    );
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returned from a pushed page — resume guide for visible tab.
    VoiceGuideService.instance.enterScreen(
      _screenForIndex(_currentIndex),
      owner: this,
    );
  }

  @override
  void didPushNext() {
    // A page was pushed on top — leaveScreen will be called by that page's
    // binder; nothing required here.
  }

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex.clamp(
        MainShellPage.homeTab,
        MainShellPage.profileTab,
      );
      VoiceGuideService.instance.enterScreen(
        _screenForIndex(_currentIndex),
        owner: this,
      );
    }
  }

  VoiceGuideScreen _screenForIndex(int index) {
    switch (index) {
      case MainShellPage.myRecipesTab:
        return VoiceGuideScreen.myRecipes;
      case MainShellPage.savedTab:
        return VoiceGuideScreen.saved;
      case MainShellPage.profileTab:
        return VoiceGuideScreen.profile;
      case MainShellPage.homeTab:
      default:
        return VoiceGuideScreen.home;
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    VoiceGuideService.instance.enterScreen(
      _screenForIndex(index),
      owner: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LandingPage(
            showTopProfileShortcut: false,
            bottomContentInset: MainShellPage.contentBottomInset,
          ),
          UserAccountPage(
            initialTab: 1,
            embedInShell: true,
            bottomContentInset: MainShellPage.contentBottomInset,
          ),
          MyCreationsPage(
            embedInShell: true,
            bottomContentInset: MainShellPage.contentBottomInset,
          ),
          UserAccountPage(
            initialTab: 0,
            embedInShell: true,
            bottomContentInset: MainShellPage.contentBottomInset,
          ),
        ],
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

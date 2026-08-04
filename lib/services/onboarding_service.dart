import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/dev_flags.dart';

/// Device-local first-launch onboarding (independent of auth).
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _prefsKey = 'foodgeniusai_onboarding_completed_v1';

  bool? _cached;

  /// Whether the user has finished the first-launch onboarding.
  Future<bool> isCompleted() async {
    if (kForceShowOnboarding) return false;

    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cached = prefs.getBool(_prefsKey) == true;
    } catch (e) {
      debugPrint('OnboardingService load error: $e');
      _cached = false;
    }
    return _cached!;
  }

  /// Call only when the user taps the final onboarding CTA.
  Future<void> markCompleted() async {
    _cached = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (e) {
      debugPrint('OnboardingService save error: $e');
    }
  }

  /// DEV / QA only — clears completion so onboarding shows again.
  Future<void> resetForDebug() async {
    if (!kDebugMode && !kForceShowOnboarding) return;
    _cached = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      debugPrint('OnboardingService: reset for debug');
    } catch (e) {
      debugPrint('OnboardingService reset error: $e');
    }
  }
}

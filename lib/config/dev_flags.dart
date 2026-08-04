/// Development / QA flags for FoodGeniusAI.
///
/// Keep all temporary test switches here so they are easy to find and disable.
library;

/// TEST ONLY — MUST BE FALSE BEFORE PRODUCTION
///
/// When `true`, the app treats the user as Premium (unlimited recipe generations
/// and Fridge Scans, no paywall) without going through RevenueCat / payment.
/// Works in Debug, Profile, and Release (does not depend on [kDebugMode]).
///
/// Does NOT change RevenueCat package IDs, entitlements, or purchase code.
/// Set to `false` to restore normal subscription enforcement immediately.
const bool kTestSubscriptionBypass = false;

/// TEST ONLY — MUST BE FALSE BEFORE PRODUCTION
///
/// When `true`, first-launch onboarding is always shown (ignores local
/// completion flag). Use to re-test the onboarding → paywall flow.
///
/// Does NOT affect production users when left `false`.
/// Alternatively call [OnboardingService.instance.resetForDebug] in debug.
const bool kForceShowOnboarding = false;

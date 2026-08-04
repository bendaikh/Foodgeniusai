import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global on/off for optional app audio (voice guide / TTS, etc.).
///
/// Cooking-generation ambience is independent of [soundEnabled] and always
/// plays during recipe generation (device volume / silent mode still apply).
class AudioSettingsService extends ChangeNotifier with WidgetsBindingObserver {
  AudioSettingsService._();

  static final AudioSettingsService instance = AudioSettingsService._();

  static const _prefsKey = 'audio_sound_enabled_v1';
  static const _firstLaunchPromptKey = 'audio_first_launch_prompt_shown_v1';
  static const _cookingAsset = 'audio/cooking_generation_loop.mp3';
  static const _cookingVolume = 0.25;

  bool _soundEnabled = false;
  bool _ready = false;
  bool _firstLaunchPromptShown = false;
  bool _observerAttached = false;

  AudioPlayer? _cookingPlayer;
  bool _cookingSoundActive = false;

  /// Optional hook so Voice Guidance can pause without a circular import.
  Future<void> Function()? pauseOverlappingAudio;

  bool get soundEnabled => _soundEnabled;
  bool get isReady => _ready;
  bool get isCookingGenerationSoundActive => _cookingSoundActive;
  bool get shouldShowFirstLaunchVoicePrompt =>
      _ready && !_firstLaunchPromptShown;

  Future<void> init() async {
    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }

    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _firstLaunchPromptShown = prefs.getBool(_firstLaunchPromptKey) == true;

      if (prefs.containsKey(_prefsKey)) {
        // Existing preference: keep it and skip the first-launch prompt.
        _soundEnabled = prefs.getBool(_prefsKey) == true;
        if (!_firstLaunchPromptShown) {
          _firstLaunchPromptShown = true;
          await prefs.setBool(_firstLaunchPromptKey, true);
        }
      } else {
        // Fresh install: stay off until the first-launch dialog choice.
        _soundEnabled = false;
      }
    } catch (e) {
      debugPrint('AudioSettingsService init error: $e');
      _soundEnabled = false;
      _firstLaunchPromptShown = false;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, enabled);
    } catch (e) {
      debugPrint('AudioSettingsService save error: $e');
    }
  }

  /// Records the first-launch voice guidance choice and never prompts again.
  Future<void> completeFirstLaunchVoicePrompt({required bool enable}) async {
    await setSoundEnabled(enable);
    _firstLaunchPromptShown = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchPromptKey, true);
    } catch (e) {
      debugPrint('AudioSettingsService first-launch prompt save error: $e');
    }
  }

  /// Debug-only: clear first-launch prompt state so the dialog can be retested.
  Future<void> resetFirstLaunchVoicePromptForDebug() async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firstLaunchPromptKey);
      _firstLaunchPromptShown = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AudioSettingsService debug reset error: $e');
    }
  }

  /// Subtle looping kitchen ambience while a recipe is being generated.
  ///
  /// Always plays during generation, independent of [soundEnabled]. Stops any
  /// previous cooking loop first so players never overlap.
  Future<void> startCookingGenerationSound() async {
    await stopCookingGenerationSound();

    try {
      final pause = pauseOverlappingAudio;
      if (pause != null) {
        await pause();
      }

      final player = AudioPlayer();
      _cookingPlayer = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_cookingVolume);
      await player.play(AssetSource(_cookingAsset));
      _cookingSoundActive = true;
    } catch (e) {
      debugPrint('AudioSettingsService cooking start error: $e');
      await stopCookingGenerationSound();
    }
  }

  /// Stops the cooking-generation loop immediately (safe to call anytime).
  Future<void> stopCookingGenerationSound() async {
    final player = _cookingPlayer;
    _cookingPlayer = null;
    _cookingSoundActive = false;
    if (player == null) return;

    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(stopCookingGenerationSound());
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }
}

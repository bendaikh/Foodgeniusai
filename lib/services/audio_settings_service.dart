import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global on/off for app audio (voice guide, cooking ambience, etc.).
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

  /// True while generation wants ambience playing (survives Android lifecycle
  /// pause so playback can resume when the app returns to foreground).
  bool _cookingSoundDesired = false;

  /// Optional hook so Voice Guidance can pause without a circular import.
  Future<void> Function()? pauseOverlappingAudio;

  bool get soundEnabled => _soundEnabled;
  bool get isReady => _ready;
  bool get isCookingGenerationSoundActive => _cookingSoundActive;
  bool get shouldShowFirstLaunchVoicePrompt =>
      _ready && !_firstLaunchPromptShown;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

    if (!enabled) {
      await stopCookingGenerationSound();
    }

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
  /// No-ops when audio is disabled. Always stops any previous cooking loop
  /// first so players never overlap.
  Future<void> startCookingGenerationSound() async {
    await _stopCookingPlayerOnly();
    _cookingSoundDesired = true;
    if (!_soundEnabled) {
      if (_isAndroid && kDebugMode) {
        debugPrint(
          'AudioSettingsService Android: cooking sound skipped '
          '(global sound toggle off)',
        );
      }
      return;
    }

    await _startCookingPlayer();
  }

  /// Stops the cooking-generation loop immediately (safe to call anytime).
  Future<void> stopCookingGenerationSound() async {
    _cookingSoundDesired = false;
    await _stopCookingPlayerOnly();
    if (_isAndroid && kDebugMode) {
      debugPrint('AudioSettingsService Android: cooking sound stopped');
    }
  }

  Future<void> _startCookingPlayer() async {
    if (!_soundEnabled || !_cookingSoundDesired) return;
    if (_cookingSoundActive && _cookingPlayer != null) return;

    try {
      final pause = pauseOverlappingAudio;
      if (pause != null) {
        await pause();
      }

      final player = AudioPlayer();
      _cookingPlayer = player;

      // Android needs an explicit media audio context for reliable asset loop
      // playback. iOS keeps audioplayers defaults (unchanged behavior).
      if (_isAndroid) {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
            ),
          ),
        );
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        if (kDebugMode) {
          debugPrint(
            'AudioSettingsService Android: cooking sound starting '
            '(asset=$_cookingAsset, volume=$_cookingVolume)',
          );
        }
      }

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_cookingVolume);

      // setSource + resume is more reliable for looping assets on Android.
      if (_isAndroid) {
        await player.setSource(AssetSource(_cookingAsset));
        await player.resume();
      } else {
        await player.play(AssetSource(_cookingAsset));
      }

      _cookingSoundActive = true;
      if (_isAndroid && kDebugMode) {
        debugPrint('AudioSettingsService Android: cooking sound started');
      }
    } catch (e, stackTrace) {
      if (_isAndroid) {
        debugPrint('AudioSettingsService Android: cooking start error: $e');
        if (kDebugMode) debugPrint('$stackTrace');
      } else {
        debugPrint('AudioSettingsService cooking start error: $e');
      }
      await _stopCookingPlayerOnly();
    }
  }

  Future<void> _stopCookingPlayerOnly() async {
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
        // iOS: keep existing behavior (stop on inactive).
        // Android: ignore inactive — it fires for transient UI and would
        // kill the cooking loop mid-generation.
        if (!_isAndroid) {
          unawaited(_stopCookingPlayerOnly());
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_stopCookingPlayerOnly());
        break;
      case AppLifecycleState.resumed:
        // Android only: resume ambience if generation still wants it.
        if (_isAndroid &&
            _cookingSoundDesired &&
            _soundEnabled &&
            !_cookingSoundActive) {
          if (kDebugMode) {
            debugPrint(
              'AudioSettingsService Android: resuming cooking sound '
              'after foreground',
            );
          }
          unawaited(_startCookingPlayer());
        }
        break;
    }
  }
}

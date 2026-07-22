import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'audio_settings_service.dart';

/// Screens that have a Voice Guide script.
enum VoiceGuideScreen {
  home,
  createRecipe,
  scanIngredients,
  generatedRecipe,
  myRecipes,
  saved,
  profile,
  kitchenSavings,
}

/// Premium AI Voice Guide — single TTS player for the whole app.
class VoiceGuideService extends ChangeNotifier with WidgetsBindingObserver {
  VoiceGuideService._() {
    WidgetsBinding.instance.addObserver(this);
    AudioSettingsService.instance.addListener(_onAudioSettingsChanged);
    // Avoid overlapping TTS with cooking ambience (no circular import).
    AudioSettingsService.instance.pauseOverlappingAudio = () => stop();
    unawaited(_configureTts());
  }

  static final VoiceGuideService instance = VoiceGuideService._();

  static const Map<VoiceGuideScreen, String> scripts = {
    VoiceGuideScreen.home:
        'Welcome to FoodGeniusAI. '
        'Choose how you\'d like to create your next recipe.',
    VoiceGuideScreen.createRecipe:
        'Enter what you\'re craving and customize your preferences '
        'before generating your recipe.',
    VoiceGuideScreen.scanIngredients:
        'Use ingredients you already have to generate recipes '
        'and reduce food waste.',
    VoiceGuideScreen.generatedRecipe:
        'Your recipe is ready. Review ingredients, instructions, '
        'and nutrition to start cooking.',
    VoiceGuideScreen.myRecipes:
        'Here you\'ll find all the recipes you\'ve created with FoodGeniusAI.',
    VoiceGuideScreen.saved:
        'Here you\'ll find all your favorite saved recipes.',
    VoiceGuideScreen.profile:
        'Manage your account, subscription, and application settings.',
    VoiceGuideScreen.kitchenSavings:
        'This section tracks your estimated kitchen savings '
        'and future food waste insights.',
  };

  final FlutterTts _tts = FlutterTts();

  VoiceGuideScreen? _activeScreen;
  Object? _owner;
  bool _isPlaying = false;
  bool _wasPlayingBeforeBackground = false;
  bool _ttsReady = false;
  int _session = 0;
  Timer? _autoPlayTimer;

  VoiceGuideScreen? get activeScreen => _activeScreen;
  bool get isPlaying => _isPlaying;
  String? get activeScript =>
      _activeScreen == null ? null : scripts[_activeScreen!];

  Future<void> _configureTts() async {
    try {
      final locale = _preferredEnglishLocale();
      await _tts.setLanguage(locale);
      // Moderate conversational pace (not rushed, not slow/robotic).
      await _tts.setSpeechRate(_speechRateForPlatform());
      await _tts.setVolume(0.9);
      // Near-neutral pitch keeps premium system voices sounding natural.
      await _tts.setPitch(1.0);

      if (!kIsWeb) {
        await _tts.setSharedInstance(true);
        await _tts.awaitSpeakCompletion(true);
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      await _preferNaturalFemaleVoice(locale);

      _tts.setStartHandler(() {
        _isPlaying = true;
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _isPlaying = false;
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _isPlaying = false;
        notifyListeners();
      });
      _tts.setErrorHandler((_) {
        _isPlaying = false;
        notifyListeners();
      });

      _ttsReady = true;
    } catch (e) {
      debugPrint('VoiceGuide TTS init error: $e');
      _ttsReady = false;
    }
  }

  /// Device language when English; otherwise fall back to en-US.
  String _preferredEnglishLocale() {
    final device = PlatformDispatcher.instance.locale;
    final language = (device.languageCode).toLowerCase();
    final country = (device.countryCode ?? '').toUpperCase();

    if (language != 'en') return 'en-US';

    switch (country) {
      case 'GB':
      case 'UK':
        return 'en-GB';
      case 'AU':
        return 'en-AU';
      case 'CA':
        return 'en-CA';
      case 'IE':
        return 'en-IE';
      case 'NZ':
        return 'en-NZ';
      case 'ZA':
        return 'en-ZA';
      case 'US':
      default:
        return 'en-US';
    }
  }

  double _speechRateForPlatform() {
    // flutter_tts rates differ by platform; keep a calm premium-assistant pace.
    if (kIsWeb) return 0.9;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 0.48;
      case TargetPlatform.android:
        return 0.45;
      default:
        return 0.48;
    }
  }

  /// Selects the highest-quality natural female English voice available.
  Future<void> _preferNaturalFemaleVoice(String preferredLocale) async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is! List) return;

      final voices =
          raw
              .whereType<Map>()
              .map((v) => v.map((k, val) => MapEntry('$k', '$val')))
              .map((v) => v.cast<String, String>())
              .toList();
      if (voices.isEmpty) return;

      final preferred = preferredLocale.toLowerCase();
      final preferredLang = preferred.split('-').first;

      Map<String, String>? best;
      var bestScore = -1;

      for (final voice in voices) {
        final score = _scoreNaturalFemaleVoice(
          voice,
          preferredLocale: preferred,
          preferredLang: preferredLang,
        );
        if (score > bestScore) {
          bestScore = score;
          best = voice;
        }
      }

      if (best == null || bestScore < 0) return;

      final name = best['name'] ?? '';
      final locale = best['locale'] ?? preferredLocale;
      await _tts.setLanguage(locale);
      await _tts.setVoice({'name': name, 'locale': locale});
      debugPrint(
        'VoiceGuide selected voice: name=$name locale=$locale score=$bestScore',
      );
    } catch (e) {
      debugPrint('VoiceGuide voice select error: $e');
    }
  }

  /// Higher score = warmer/more natural female voice for the device locale.
  int _scoreNaturalFemaleVoice(
    Map<String, String> voice, {
    required String preferredLocale,
    required String preferredLang,
  }) {
    final name = (voice['name'] ?? '').toLowerCase();
    final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
    final gender = (voice['gender'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final identifier = [
      name,
      voice['identifier'] ?? '',
      voice['id'] ?? '',
      quality,
    ].join(' ').toLowerCase();

    // English only.
    if (!locale.startsWith('en') && !name.contains('english')) {
      return -1;
    }

    var score = 0;

    // Locale match (device first).
    if (locale == preferredLocale ||
        locale.replaceAll('-', '_') == preferredLocale.replaceAll('-', '_')) {
      score += 120;
    } else if (locale.startsWith(preferredLang)) {
      score += 40;
    }

    // Strong preference for known natural female system voices.
    const premiumFemaleByLocale = <String, List<String>>{
      'en-us': [
        'zoe',
        'ava',
        'nicky',
        'samantha',
        'susan',
        'allison',
        'jenny',
        'emma',
      ],
      'en-gb': [
        'kate',
        'serena',
        'stephanie',
        'martha',
        'fiona',
        'libby',
      ],
      'en-au': ['karen', 'catherine', 'lee'],
      'en-ca': ['samantha', 'ava', 'zoe'],
      'en-ie': ['moira'],
      'en-za': ['tessa'],
      'en-nz': ['karen', 'tessa'],
    };

    final localeKeys = <String>[
      preferredLocale,
      if (preferredLocale.length >= 5) preferredLocale.substring(0, 5),
      'en-us',
    ];
    for (final key in localeKeys) {
      final names = premiumFemaleByLocale[key];
      if (names == null) continue;
      for (var i = 0; i < names.length; i++) {
        if (name.contains(names[i])) {
          // Earlier entries are preferred.
          score += 100 - (i * 4);
          break;
        }
      }
    }

    // Generic female markers.
    if (gender.contains('female') ||
        name.contains('female') ||
        name.contains('woman') ||
        identifier.contains('#female')) {
      score += 55;
    }

    // Prefer enhanced / premium / neural / online HQ voices.
    if (identifier.contains('premium') ||
        identifier.contains('enhanced') ||
        identifier.contains('neural') ||
        identifier.contains('natural') ||
        identifier.contains('siri') ||
        quality.contains('enhanced') ||
        quality.contains('premium')) {
      score += 70;
    }
    if (identifier.contains('network') ||
        identifier.contains('online') ||
        identifier.contains('cloud')) {
      score += 25;
    }
    // Prefer installed high-quality locals over compact/robotic.
    if (identifier.contains('compact') ||
        identifier.contains('eloquence') ||
        identifier.contains('novelty')) {
      score -= 40;
    }
    if (identifier.contains('robot') ||
        identifier.contains('whisper') ||
        name.contains('bad news') ||
        name.contains('good news') ||
        name.contains('bells')) {
      score -= 80;
    }

    // Android Google neural-ish local female codes (examples).
    const androidFemaleHints = [
      'en-us-x-sfg',
      'en-us-x-sfg-local',
      'en-us-x-sfg-network',
      'en-gb-x-gba',
      'en-gb-x-gbc',
      'en-au-x-afh',
      'en-au-x-afc',
      'en-ca-x-',
    ];
    for (final hint in androidFemaleHints) {
      if (name.contains(hint) || identifier.contains(hint)) {
        score += 60;
        break;
      }
    }

    // Mild boost for explicit "female" Google labels.
    if (name.contains('english') && name.contains('female')) {
      score += 45;
    }

    return score;
  }

  /// Called when a screen becomes the active guide context.
  Future<void> enterScreen(
    VoiceGuideScreen screen, {
    bool autoPlay = true,
    Object? owner,
  }) async {
    _autoPlayTimer?.cancel();

    final sameScreen = _activeScreen == screen;
    _owner = owner ?? screen;

    if (!sameScreen) {
      await stop(notify: false);
      _activeScreen = screen;
      notifyListeners();
    } else if (_isPlaying) {
      // Re-entering while already playing this screen: leave it alone.
      return;
    }

    if (!autoPlay) return;
    if (!AudioSettingsService.instance.soundEnabled) return;

    final session = ++_session;
    _autoPlayTimer = Timer(const Duration(milliseconds: 500), () {
      if (session != _session) return;
      if (_activeScreen != screen) return;
      if (!AudioSettingsService.instance.soundEnabled) return;
      unawaited(play(fromStart: true));
    });
  }

  /// Called when a screen is left / disposed.
  ///
  /// [owner] prevents a disposing nested route from cancelling a guide that
  /// has already been reclaimed by the route underneath (same script).
  Future<void> leaveScreen(VoiceGuideScreen screen, {Object? owner}) async {
    if (_activeScreen != screen) return;
    if (owner != null && _owner != null && !identical(_owner, owner)) {
      return;
    }
    _autoPlayTimer?.cancel();
    await stop();
  }

  Future<void> play({bool fromStart = true}) async {
    if (!AudioSettingsService.instance.soundEnabled) return;

    final screen = _activeScreen;
    final script = screen == null ? null : scripts[screen];
    if (script == null || script.isEmpty) return;

    if (!_ttsReady) {
      await _configureTts();
      if (!_ttsReady) return;
    }

    _autoPlayTimer?.cancel();
    final session = ++_session;

    try {
      if (_isPlaying || fromStart) {
        await _tts.stop();
      }
      if (session != _session) return;

      _isPlaying = true;
      notifyListeners();

      final result = await _tts.speak(script);
      if (session != _session) return;
      if (result != 1 && result != true) {
        // Some platforms return void/null on success; only clear on hard failure.
        if (result == 0 || result == false) {
          _isPlaying = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('VoiceGuide play error: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stop({bool notify = true}) async {
    _autoPlayTimer?.cancel();
    _session++;
    try {
      await _tts.stop();
    } catch (_) {}
    if (_isPlaying) {
      _isPlaying = false;
      if (notify) notifyListeners();
    } else if (notify) {
      // Still notify if UI needs to reset pulse state.
    }
  }

  void _onAudioSettingsChanged() {
    if (!AudioSettingsService.instance.soundEnabled) {
      unawaited(stop());
    }
  }

  /// Center FAB legacy helper (Scan now uses the center button).
  /// playing → stop; stopped → replay when sound is enabled.
  Future<void> toggleCenterButton() async {
    if (_isPlaying) {
      await stop();
    } else if (AudioSettingsService.instance.soundEnabled) {
      await play(fromStart: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_isPlaying) {
          _wasPlayingBeforeBackground = true;
          unawaited(stop());
        }
        break;
      case AppLifecycleState.resumed:
        // Resume only if we intentionally paused due to background.
        if (_wasPlayingBeforeBackground && _activeScreen != null) {
          _wasPlayingBeforeBackground = false;
          // Do not auto-resume speech after background — avoids surprise audio.
        } else {
          _wasPlayingBeforeBackground = false;
        }
        break;
      case AppLifecycleState.detached:
        unawaited(stop());
        break;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    AudioSettingsService.instance.removeListener(_onAudioSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts.stop());
    super.dispose();
  }
}

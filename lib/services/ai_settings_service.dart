import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../firebase_options.dart';
import '../models/ai_settings_model.dart';

class AISettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsDoc = 'ai_settings';
  static const String _projectId = 'gourmetai-c432b';

  http.Client? _httpClient;

  http.Client get _client {
    if (kIsWeb) return http.Client();
    _httpClient ??= IOClient(
      HttpClient()
        ..connectionTimeout = const Duration(seconds: 20)
        ..idleTimeout = const Duration(seconds: 20),
    );
    return _httpClient!;
  }

  Future<void> saveSettings(AISettingsModel settings) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc(_settingsDoc)
          .set(settings.toFirestore());
    } catch (e) {
      throw Exception('Failed to save AI settings: $e');
    }
  }

  Future<AISettingsModel> getSettings() async {
    // Android Firestore native SDK often reports "unavailable" on emulators.
    // Use direct HTTPS on mobile; keep SDK path for web/desktop.
    if (_useRestFirst) {
      try {
        return await _getSettingsFromRestApi();
      } catch (restError) {
        try {
          return await _getSettingsFromFirestore();
        } catch (sdkError) {
          throw Exception(
            'Cannot load AI settings. Check that your phone/emulator has internet, then try again.\n'
            'Network error: $restError',
          );
        }
      }
    }

    try {
      return await _getSettingsFromFirestore();
    } catch (sdkError) {
      try {
        return await _getSettingsFromRestApi();
      } catch (restError) {
        throw Exception('Failed to load AI settings: $sdkError');
      }
    }
  }

  bool get _useRestFirst =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<AISettingsModel> _getSettingsFromFirestore() async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final doc = await _firestore
            .collection('admin_settings')
            .doc(_settingsDoc)
            .get(const GetOptions(source: Source.server));

        if (doc.exists) {
          return AISettingsModel.fromFirestore(doc);
        }
        return AISettingsModel.defaultSettings();
      } catch (e) {
        lastError = e;
        if (attempt == 1) break;
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
    throw Exception('$lastError');
  }

  Future<AISettingsModel> _getSettingsFromRestApi() async {
    final urls = <Uri>[
      _restUrl(apiKey: null),
      _restUrl(apiKey: DefaultFirebaseOptions.web.apiKey),
      _restUrl(apiKey: DefaultFirebaseOptions.android.apiKey),
    ];

    Object? lastError;
    for (final url in urls) {
      try {
        final response = await _client
            .get(url)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final fields = data['fields'] as Map<String, dynamic>?;
        if (fields == null || fields.isEmpty) {
          return AISettingsModel.defaultSettings();
        }

        return AISettingsModel.fromMap(_decodeRestFields(fields));
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('$lastError');
  }

  Uri _restUrl({String? apiKey}) {
    final base =
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/admin_settings/$_settingsDoc';
    if (apiKey == null || apiKey.isEmpty) return Uri.parse(base);
    return Uri.parse('$base?key=$apiKey');
  }

  Map<String, dynamic> _decodeRestFields(Map<String, dynamic> fields) {
    final decoded = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is! Map<String, dynamic>) return;
      if (value.containsKey('stringValue')) {
        decoded[key] = value['stringValue'];
      } else if (value.containsKey('integerValue')) {
        decoded[key] = int.tryParse('${value['integerValue']}');
      } else if (value.containsKey('doubleValue')) {
        decoded[key] = (value['doubleValue'] as num).toDouble();
      } else if (value.containsKey('booleanValue')) {
        decoded[key] = value['booleanValue'];
      }
    });
    return decoded;
  }

  Stream<AISettingsModel> settingsStream() {
    return _firestore
        .collection('admin_settings')
        .doc(_settingsDoc)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return AISettingsModel.fromFirestore(doc);
      } else {
        return AISettingsModel.defaultSettings();
      }
    });
  }
}

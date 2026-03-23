import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_settings_model.dart';

class AISettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsDoc = 'ai_settings';

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
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc(_settingsDoc)
          .get();

      if (doc.exists) {
        return AISettingsModel.fromFirestore(doc);
      } else {
        return AISettingsModel.defaultSettings();
      }
    } catch (e) {
      throw Exception('Failed to load AI settings: $e');
    }
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

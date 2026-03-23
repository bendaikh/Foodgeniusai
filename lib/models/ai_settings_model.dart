import 'package:cloud_firestore/cloud_firestore.dart';

class AISettingsModel {
  final String provider; // 'OpenAI', 'Anthropic', 'Google'
  final String? openaiApiKey;
  final String? openaiModel;
  final int? maxTokens;
  final double? temperature;
  final String? imageProvider; // 'DALL-E 3', 'DALL-E 2', 'Stable Diffusion'
  final DateTime? updatedAt;

  AISettingsModel({
    required this.provider,
    this.openaiApiKey,
    this.openaiModel,
    this.maxTokens,
    this.temperature,
    this.imageProvider,
    this.updatedAt,
  });

  factory AISettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AISettingsModel(
      provider: data['provider'] ?? 'OpenAI',
      openaiApiKey: data['openaiApiKey'],
      openaiModel: data['openaiModel'] ?? 'gpt-4o-mini',
      maxTokens: data['maxTokens'] ?? 2000,
      temperature: (data['temperature'] ?? 0.7).toDouble(),
      imageProvider: data['imageProvider'] ?? 'DALL-E 3',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'provider': provider,
      'openaiApiKey': openaiApiKey,
      'openaiModel': openaiModel,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'imageProvider': imageProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AISettingsModel.defaultSettings() {
    return AISettingsModel(
      provider: 'OpenAI',
      openaiModel: 'gpt-4o-mini',
      maxTokens: 2000,
      temperature: 0.7,
      imageProvider: 'DALL-E 3',
    );
  }
}

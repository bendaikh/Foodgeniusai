import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';

/// Calls Firebase callable functions over HTTP JSON.
///
/// The `cloud_functions` SDK deserializes some integers as [Int64], which
/// throws on Flutter Web (`dart2js`). HTTP + JSON avoids that path.
class CloudFunctionHttp {
  static const _region = 'us-central1';

  static String get _baseUrl {
    final projectId = DefaultFirebaseOptions.web.projectId;
    return 'https://$_region-$projectId.cloudfunctions.net';
  }

  static Future<Map<String, dynamic>> call(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/$functionName'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'data': data ?? {}}),
    );

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw Exception(
        'Invalid response from $functionName (HTTP ${response.statusCode})',
      );
    }

    final error = body['error'];
    if (error != null) {
      if (error is Map) {
        throw Exception(
          error['message']?.toString() ?? 'Cloud function error',
        );
      }
      throw Exception(error.toString());
    }

    final result = body['result'];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {};
  }
}

int cloudFunctionInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

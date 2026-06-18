import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DodoPaymentService {
  static final DodoPaymentService _instance = DodoPaymentService._internal();
  factory DodoPaymentService() => _instance;
  DodoPaymentService._internal();

  String? _apiKey;
  String? _businessId;
  bool _isTestMode = true;

  String get baseUrl => _isTestMode
      ? 'https://test.dodopayments.com'
      : 'https://live.dodopayments.com';

  Future<void> loadConfiguration() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('payment_settings')
          .get();

      if (doc.exists) {
        final data = doc.data();
        _apiKey = data?['dodo_api_key'] as String?;
        _businessId = data?['dodo_business_id'] as String?;
        _isTestMode = data?['dodo_test_mode'] as bool? ?? true;
      }
    } catch (e) {
      print('Error loading DodoPayment configuration: $e');
    }
  }

  void applyConfiguration({
    required String apiKey,
    required String businessId,
    required bool testMode,
  }) {
    _apiKey = apiKey.trim();
    _businessId = businessId.trim();
    _isTestMode = testMode;
  }

  Future<void> saveConfiguration({
    required String apiKey,
    required String businessId,
    required bool testMode,
  }) async {
    applyConfiguration(
      apiKey: apiKey,
      businessId: businessId,
      testMode: testMode,
    );

    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('payment_settings')
          .set({
        'dodo_api_key': _apiKey,
        'dodo_business_id': _businessId,
        'dodo_test_mode': _isTestMode,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save configuration: $e');
    }
  }

  bool get isConfigured => _apiKey != null && _businessId != null;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    if (_businessId != null && _businessId!.isNotEmpty) {
      headers['business-id'] = _businessId!;
    }
    return headers;
  }

  Future<_DodoHttpResult> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    if (kIsWeb) {
      return _requestViaCloudFunction(
        method: method,
        path: path,
        body: body,
      );
    }

    return _requestDirect(
      method: method,
      path: path,
      body: body,
    );
  }

  Future<_DodoHttpResult> _requestDirect({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: _headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: _headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    return _DodoHttpResult(
      statusCode: response.statusCode,
      body: response.body,
      url: uri.toString(),
    );
  }

  Future<_DodoHttpResult> _requestViaCloudFunction({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    try {
      // Get the current user's ID token for authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to use payment features');
      }
      
      final idToken = await user.getIdToken();
      
      // Call the Cloud Function via HTTP (avoids CORS issues with callable SDK)
      const functionUrl = 'https://us-central1-gourmetai-c432b.cloudfunctions.net/dodoPaymentsProxy';
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'method': method,
          'path': path,
          if (body != null) 'body': body,
        }),
      );

      if (response.statusCode != 200) {
        String errorMsg = 'Cloud Function returned ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['error'] != null) {
            errorMsg = errorData['error'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }

      final Map<String, dynamic> envelope = jsonDecode(response.body);
      final statusCode = int.tryParse(envelope['statusCode']?.toString() ?? '500') ?? 500;
      final url = envelope['url']?.toString() ?? '$baseUrl$path';
      final responseBody = envelope['body']?.toString() ?? '';

      return _DodoHttpResult(
        statusCode: statusCode,
        body: responseBody,
        url: url,
      );
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        throw Exception('Network error connecting to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  /// Converts a dollar amount (e.g. 10.00) to cents for the Dodo API.
  static int dollarsToCents(double dollars) => (dollars * 100).round();

  /// Extracts price in cents from a Dodo product response.
  static int extractPriceCents(Map<String, dynamic> product) {
    final price = product['price'];
    if (price is int) return price;
    if (price is num) return price.round();
    if (price is Map) {
      final nested = price['price'];
      if (nested is int) return nested;
      if (nested is num) return nested.round();
    }
    return 0;
  }

  static String extractCurrency(Map<String, dynamic> product) {
    final price = product['price'];
    if (price is Map && price['currency'] != null) {
      return price['currency'].toString();
    }
    return product['currency'] as String? ?? 'USD';
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required String currency,
    int? price,
    double? priceInDollars,
    String? imageUrl,
  }) async {
    if (!isConfigured) throw Exception('DodoPayment not configured');

    final priceCents = price ??
        (priceInDollars != null ? dollarsToCents(priceInDollars) : null);
    if (priceCents == null || priceCents <= 0) {
      throw Exception('A valid price is required.');
    }

    final response = await _request(
      method: 'POST',
      path: '/products',
      body: {
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'tax_category': 'digital_products',
        'price': {
          'type': 'one_time_price',
          'price': priceCents,
          'currency': currency,
          'discount': 0,
          'purchasing_power_parity': false,
        },
        if (imageUrl != null) 'image': imageUrl,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create product: ${response.body}');
  }

  Future<Map<String, dynamic>> createCheckoutSession({
    required List<Map<String, dynamic>> items,
    required String successUrl,
    required String cancelUrl,
    String? customerEmail,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isConfigured) throw Exception('DodoPayment not configured');

    final response = await _request(
      method: 'POST',
      path: '/checkouts',
      body: {
        'product_cart': items,
        'return_url': successUrl,
        if (customerEmail != null)
          'customer': {'email': customerEmail},
        if (metadata != null) 'metadata': metadata,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create checkout session: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    if (!isConfigured) throw Exception('DodoPayment not configured');

    final response = await _request(method: 'GET', path: '/products');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
    throw Exception('Failed to fetch products: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    if (!isConfigured) throw Exception('DodoPayment not configured');

    final response = await _request(method: 'GET', path: '/subscriptions');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(
        data['items'] ?? data['subscriptions'] ?? [],
      );
    }
    throw Exception('Failed to fetch subscriptions: ${response.body}');
  }

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    if (!isConfigured) throw Exception('DodoPayment not configured');

    final response = await _request(
      method: 'GET',
      path: '/payments/$paymentId',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch payment: ${response.body}');
  }

  Future<DodoConnectionTestResult> testConnection() async {
    if (!isConfigured) {
      return const DodoConnectionTestResult(
        success: false,
        message: 'API Key and Business ID are required.',
      );
    }

    final url = kIsWeb ? 'Firebase Function → $baseUrl/products' : '$baseUrl/products';
    try {
      final response = await _request(method: 'GET', path: '/products');

      if (response.statusCode == 200) {
        return DodoConnectionTestResult(
          success: true,
          message: kIsWeb
              ? 'Connected via secure server proxy (${_isTestMode ? 'test' : 'live'} mode).'
              : 'Connected to ${_isTestMode ? 'test' : 'live'} API.',
          url: response.url,
        );
      }

      String details = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          details = decoded['error'].toString();
        }
      } catch (_) {}

      return DodoConnectionTestResult(
        success: false,
        message: details.isNotEmpty
            ? details
            : 'HTTP ${response.statusCode}',
        url: response.url,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('Connection test failed ($url): $e');
      final message = e.toString();
      if (message.contains('Failed to fetch') ||
          message.contains('ClientException')) {
        return DodoConnectionTestResult(
          success: false,
          message:
              'Browser blocked the Dodo API call. Deploy Firebase Functions (firebase deploy --only functions) or try Chrome Incognito with extensions disabled.',
          url: url,
        );
      }
      return DodoConnectionTestResult(
        success: false,
        message: message,
        url: url,
      );
    }
  }

  String getCheckoutUrl(String sessionId) {
    final baseCheckoutUrl = _isTestMode
        ? 'https://test.checkout.dodopayments.com'
        : 'https://checkout.dodopayments.com';
    return '$baseCheckoutUrl/session/$sessionId';
  }
}

class _DodoHttpResult {
  final int statusCode;
  final String body;
  final String url;

  const _DodoHttpResult({
    required this.statusCode,
    required this.body,
    required this.url,
  });
}

class DodoConnectionTestResult {
  final bool success;
  final String message;
  final String? url;
  final int? statusCode;

  const DodoConnectionTestResult({
    required this.success,
    required this.message,
    this.url,
    this.statusCode,
  });
}

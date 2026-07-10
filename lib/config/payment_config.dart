/// Payment redirect URLs and deep-link settings for mobile checkout.
class PaymentConfig {
  PaymentConfig._();

  /// Hosted return pages for mobile browser checkout (lightweight HTML, not the Flutter app).
  static const String mobileReturnOrigin = 'https://gourmetai-c432b.web.app';

  static const String mobileSuccessPath = '/mobile-payment-success.html';
  static const String mobileCancelPath = '/mobile-payment-cancel.html';

  static String get mobileSuccessUrl =>
      '$mobileReturnOrigin$mobileSuccessPath?source=mobile';

  static String get mobileCancelUrl =>
      '$mobileReturnOrigin$mobileCancelPath?source=mobile';

  /// Custom URL scheme used to reopen the native app after browser checkout.
  static const String appDeepLinkScheme = 'gourmetai';
  static const String appDeepLinkHost = 'payment';

  static String buildAppDeepLink({
    required String path,
    Map<String, String> params = const {},
  }) {
    final uri = Uri(
      scheme: appDeepLinkScheme,
      host: appDeepLinkHost,
      path: path,
      queryParameters: params.isEmpty ? null : params,
    );
    return uri.toString();
  }
}

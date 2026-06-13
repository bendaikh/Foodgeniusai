import 'package:url_launcher/url_launcher.dart';

Future<void> redirectToCheckout(String checkoutUrl) async {
  final uri = Uri.parse(checkoutUrl);
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    throw Exception('Could not open checkout. Please try again.');
  }
}

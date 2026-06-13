import 'dart:html' as html;

Future<void> redirectToCheckout(String checkoutUrl) async {
  html.window.location.href = checkoutUrl;
}

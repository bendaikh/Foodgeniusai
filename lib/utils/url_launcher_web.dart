// Web implementation using dart:html
import 'dart:html' as html;

Future<void> openUrl(String url) async {
  html.window.open(url, '_blank');
}

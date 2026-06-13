import 'package:flutter_web_plugins/url_strategy.dart';
import '../services/favicon_service.dart';

Future<void> platformInit() async {
  usePathUrlStrategy();
  await FaviconService().initialize();
}

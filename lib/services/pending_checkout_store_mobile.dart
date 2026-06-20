import 'package:shared_preferences/shared_preferences.dart';

class PendingCheckoutStore {
  PendingCheckoutStore._();
  static final PendingCheckoutStore instance = PendingCheckoutStore._();

  static const _storageKey = 'gourmetai_pending_checkout_id';

  Future<void> save(String checkoutId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, checkoutId);
  }

  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

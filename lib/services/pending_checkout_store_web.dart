import 'dart:html' as html;

class PendingCheckoutStore {
  PendingCheckoutStore._();
  static final PendingCheckoutStore instance = PendingCheckoutStore._();

  static const _storageKey = 'gourmetai_pending_checkout_id';

  Future<void> save(String checkoutId) async {
    html.window.sessionStorage[_storageKey] = checkoutId;
  }

  Future<String?> load() async {
    return html.window.sessionStorage[_storageKey];
  }

  Future<void> clear() async {
    html.window.sessionStorage.remove(_storageKey);
  }
}

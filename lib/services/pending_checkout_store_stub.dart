class PendingCheckoutStore {
  PendingCheckoutStore._();
  static final PendingCheckoutStore instance = PendingCheckoutStore._();

  static const _storageKey = 'gourmetai_pending_checkout_id';

  Future<void> save(String checkoutId) async {}

  Future<String?> load() async => null;

  Future<void> clear() async {}
}

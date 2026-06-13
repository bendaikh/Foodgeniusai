class FaviconService {
  static final FaviconService _instance = FaviconService._internal();
  factory FaviconService() => _instance;
  FaviconService._internal();

  Future<void> initialize() async {}

  Future<void> refreshFavicon() async {}

  void cacheUploadedFavicon({
    required String dataUrl,
    required String remoteUrl,
    String? version,
  }) {}
}

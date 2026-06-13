import 'dart:async';
import 'dart:html' as html;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dynamically updates the browser favicon from Firestore settings.
///
/// Design notes (please read before changing):
///
///   * `web/index.html` declares same-origin static favicons
///     (`/favicon.ico` + multiple `/favicon-*.png` and `/icons/Icon-*.png`).
///     Those are the source of truth for Google Search and first paint.
///     Cross-origin Firebase Storage URLs must NEVER replace them in the DOM
///     (Google Search requires a crawlable same-domain favicon).
///   * This service only swaps <link> tags for a local `data:` URL cached
///     after an admin upload in this browser. Remote Storage URLs are kept
///     in localStorage for bookkeeping but the tab icon stays on the static
///     same-origin files until `tools/sync_favicons_from_firebase.ps1` +
///     redeploy updates the web bundle.
///   * Dynamic <link> tags are tagged with `data-dynamic="1"`.
class FaviconService {
  static final FaviconService _instance = FaviconService._internal();
  factory FaviconService() => _instance;
  FaviconService._internal();

  /// Keep these in sync with the bootstrap script in web/index.html.
  static const String _urlKey = 'app_favicon_url_v1';
  static const String _dataKey = 'app_favicon_data_v1';
  static const String _verKey = 'app_favicon_version_v1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  String? _appliedUrl;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await Firebase.initializeApp();
      await _loadAndApplyFavicon();
      _watchFaviconChanges();
    } catch (e) {
      // ignore: avoid_print
      print('FaviconService init error: $e');
    }
  }

  Future<void> _loadAndApplyFavicon() async {
    try {
      final cachedDataUrl = _readCachedDataUrl();
      if (cachedDataUrl != null) {
        await _safelyApply(cachedDataUrl);
      }

      final snap = await _firestore
          .collection('admin_settings')
          .doc('app_settings')
          .get();
      final data = snap.data();
      final url = data?['faviconUrl'] as String?;
      final version = _readVersion(data);
      if (url != null && url.isNotEmpty) {
        _rememberRemote(url, version: version);
      } else {
        _clearCache();
      }
    } catch (e) {
      // ignore: avoid_print
      print('FaviconService load error: $e');
    }
  }

  void _watchFaviconChanges() {
    _firestore
        .collection('admin_settings')
        .doc('app_settings')
        .snapshots()
        .listen((snap) async {
      final data = snap.data();
      final url = data?['faviconUrl'] as String?;
      final version = _readVersion(data);
      if (url != null && url.isNotEmpty) {
        if (url != _appliedUrl) _rememberRemote(url, version: version);
      } else {
        _clearCache();
      }
    }, onError: (e) {
      // ignore: avoid_print
      print('FaviconService watch error: $e');
    });
  }

  /// Pulls a stable version string out of the Firestore doc so the bootstrap
  /// script can use it as a cache-buster. Prefers the server timestamp, falls
  /// back to the raw URL (which changes when the download token rotates).
  String? _readVersion(Map<String, dynamic>? data) {
    if (data == null) return null;
    final ts = data['faviconUpdatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch.toString();
    final url = data['faviconUrl'];
    if (url is String && url.isNotEmpty) return url;
    return null;
  }

  void _clearCache() {
    try {
      html.window.localStorage.remove(_urlKey);
      html.window.localStorage.remove(_dataKey);
      html.window.localStorage.remove(_verKey);
    } catch (_) {}
  }

  /// Lets the upload UI seed the cached base64 image right after picking a
  /// file, so the very next reload is zero-network instant. Caller passes
  /// the canonical (non-busted) Storage URL too so other devices can pick
  /// it up via Firestore on their own.
  void cacheUploadedFavicon({
    required String dataUrl,
    required String remoteUrl,
    String? version,
  }) {
    try {
      final ls = html.window.localStorage;
      ls[_dataKey] = dataUrl;
      ls[_urlKey] = remoteUrl;
      ls[_verKey] = version ?? DateTime.now().millisecondsSinceEpoch.toString();
      _appliedUrl = remoteUrl;
    } catch (_) {}
  }

  String? _readCachedDataUrl() {
    try {
      final dataUrl = html.window.localStorage[_dataKey];
      if (dataUrl != null && dataUrl.startsWith('data:')) return dataUrl;
    } catch (_) {}
    return null;
  }

  void _rememberRemote(String url, {String? version}) {
    _appliedUrl = url;
    try {
      final ls = html.window.localStorage;
      ls[_urlKey] = url;
      if (version != null) ls[_verKey] = version;
    } catch (_) {}
  }

  Future<void> _safelyApply(String url, {String? version}) async {
    // Only swap DOM for inline data URLs (admin preview in this browser).
    // Remote URLs stay on the static same-origin icons for Google Search.
    if (!url.startsWith('data:')) {
      _rememberRemote(url, version: version);
      return;
    }

    final t = DateTime.now().millisecondsSinceEpoch;
    final busted = '$url#fav=$t';

    final ok = await _preload(busted);
    if (!ok) {
      // ignore: avoid_print
      print('FaviconService: data URL failed to preload, keeping static favicon');
      return;
    }

    _swapLinks(busted);
    _appliedUrl = url;
    try {
      final ls = html.window.localStorage;
      ls[_dataKey] = url;
      ls[_verKey] = version ?? t.toString();
    } catch (_) {}
    // ignore: avoid_print
    print('FaviconService: applied cached data URL favicon');
  }

  Future<bool> _preload(String url) {
    final completer = Completer<bool>();
    final img = html.ImageElement();
    StreamSubscription? loadSub;
    StreamSubscription? errSub;
    void finish(bool v) {
      if (completer.isCompleted) return;
      loadSub?.cancel();
      errSub?.cancel();
      completer.complete(v);
    }

    loadSub = img.onLoad.listen((_) => finish(true));
    errSub = img.onError.listen((_) => finish(false));
    img.src = url;

    Timer(const Duration(seconds: 6), () => finish(false));
    return completer.future;
  }

  void _swapLinks(String url) {
    final head = html.document.head;
    if (head == null) return;

    // Important: wipe EVERY favicon link, including the static ones from
    // index.html. The static tags declare specific sizes (32x32, 48x48,
    // 192x192, 512x512) and Chrome happily keeps using `/favicon-32.png`
    // for the tab even after we add a new <link> without a size. By the
    // time we get here we already pre-loaded the new image successfully,
    // so it's safe to make the dynamic favicon the sole source of truth.
    head.querySelectorAll('link[rel~="icon"]').forEach((n) => n.remove());
    head
        .querySelectorAll('link[rel="shortcut icon"]')
        .forEach((n) => n.remove());
    head
        .querySelectorAll('link[rel="apple-touch-icon"]')
        .forEach((n) => n.remove());
    head
        .querySelectorAll('link[rel="apple-touch-icon-precomposed"]')
        .forEach((n) => n.remove());

    void add(String rel, {String? sizes, String? type}) {
      final link = html.LinkElement()
        ..rel = rel
        ..href = url
        ..setAttribute('data-dynamic', '1');
      if (type != null) link.type = type;
      if (sizes != null) link.setAttribute('sizes', sizes);
      head.append(link);
    }

    // Cover every size browsers / OS / PWAs ask for, all pointing at the
    // user's uploaded image. The image will be scaled by the browser.
    add('icon', type: 'image/png', sizes: '16x16');
    add('icon', type: 'image/png', sizes: '32x32');
    add('icon', type: 'image/png', sizes: '48x48');
    add('icon', type: 'image/png', sizes: '192x192');
    add('icon', type: 'image/png', sizes: '512x512');
    add('icon', type: 'image/png', sizes: 'any');
    add('shortcut icon', type: 'image/png');
    add('apple-touch-icon', sizes: '180x180');

    // Chrome/Edge sometimes keep the previous favicon cached and won't
    // redraw until the document is mutated. Tiny title round-trip nudges
    // the tab to re-pick the favicon immediately.
    final originalTitle = html.document.title;
    html.document.title = '$originalTitle\u200B';
    Timer(const Duration(milliseconds: 60), () {
      html.document.title = originalTitle;
    });
  }

  /// Re-pull from Firestore (called after admin uploads a new favicon).
  Future<void> refreshFavicon() => _loadAndApplyFavicon();
}

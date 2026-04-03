import 'package:cloud_firestore/cloud_firestore.dart';

class SeoSettings {
  final String siteName;
  final String metaTitle;
  final String metaDescription;
  final String metaKeywords;
  final String ogTitle;
  final String ogDescription;
  final String ogImage;
  final String twitterHandle;
  final String googleAnalyticsId;
  final String googleSearchConsole;
  final String robotsTxt;
  final String sitemapUrl;
  final String canonicalUrl;

  SeoSettings({
    this.siteName = '',
    this.metaTitle = '',
    this.metaDescription = '',
    this.metaKeywords = '',
    this.ogTitle = '',
    this.ogDescription = '',
    this.ogImage = '',
    this.twitterHandle = '',
    this.googleAnalyticsId = '',
    this.googleSearchConsole = '',
    this.robotsTxt = '',
    this.sitemapUrl = '',
    this.canonicalUrl = '',
  });

  factory SeoSettings.fromMap(Map<String, dynamic> data) {
    return SeoSettings(
      siteName: data['siteName'] ?? '',
      metaTitle: data['metaTitle'] ?? '',
      metaDescription: data['metaDescription'] ?? '',
      metaKeywords: data['metaKeywords'] ?? '',
      ogTitle: data['ogTitle'] ?? '',
      ogDescription: data['ogDescription'] ?? '',
      ogImage: data['ogImage'] ?? '',
      twitterHandle: data['twitterHandle'] ?? '',
      googleAnalyticsId: data['googleAnalyticsId'] ?? '',
      googleSearchConsole: data['googleSearchConsole'] ?? '',
      robotsTxt: data['robotsTxt'] ?? '',
      sitemapUrl: data['sitemapUrl'] ?? '',
      canonicalUrl: data['canonicalUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteName': siteName,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'metaKeywords': metaKeywords,
      'ogTitle': ogTitle,
      'ogDescription': ogDescription,
      'ogImage': ogImage,
      'twitterHandle': twitterHandle,
      'googleAnalyticsId': googleAnalyticsId,
      'googleSearchConsole': googleSearchConsole,
      'robotsTxt': robotsTxt,
      'sitemapUrl': sitemapUrl,
      'canonicalUrl': canonicalUrl,
    };
  }
}

class SeoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final SeoService _instance = SeoService._internal();
  factory SeoService() => _instance;
  SeoService._internal();

  Future<SeoSettings> getSeoSettings() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc('seo_settings')
          .get();

      if (doc.exists && doc.data() != null) {
        return SeoSettings.fromMap(doc.data()!);
      }
      return SeoSettings();
    } catch (e) {
      print('Error loading SEO settings: $e');
      return SeoSettings();
    }
  }

  Stream<SeoSettings> getSeoSettingsStream() {
    return _firestore
        .collection('admin_settings')
        .doc('seo_settings')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return SeoSettings.fromMap(doc.data()!);
      }
      return SeoSettings();
    });
  }

  Future<void> updateSeoSettings(SeoSettings settings) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc('seo_settings')
          .set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating SEO settings: $e');
      rethrow;
    }
  }

  String generateMetaTags(SeoSettings settings) {
    final buffer = StringBuffer();
    
    if (settings.metaTitle.isNotEmpty) {
      buffer.writeln('<meta name="title" content="${_escapeHtml(settings.metaTitle)}" />');
    }
    
    if (settings.metaDescription.isNotEmpty) {
      buffer.writeln('<meta name="description" content="${_escapeHtml(settings.metaDescription)}" />');
    }
    
    if (settings.metaKeywords.isNotEmpty) {
      buffer.writeln('<meta name="keywords" content="${_escapeHtml(settings.metaKeywords)}" />');
    }
    
    if (settings.ogTitle.isNotEmpty) {
      buffer.writeln('<meta property="og:title" content="${_escapeHtml(settings.ogTitle)}" />');
    }
    
    if (settings.ogDescription.isNotEmpty) {
      buffer.writeln('<meta property="og:description" content="${_escapeHtml(settings.ogDescription)}" />');
    }
    
    if (settings.ogImage.isNotEmpty) {
      buffer.writeln('<meta property="og:image" content="${_escapeHtml(settings.ogImage)}" />');
    }
    
    if (settings.canonicalUrl.isNotEmpty) {
      buffer.writeln('<meta property="og:url" content="${_escapeHtml(settings.canonicalUrl)}" />');
      buffer.writeln('<link rel="canonical" href="${_escapeHtml(settings.canonicalUrl)}" />');
    }
    
    buffer.writeln('<meta property="og:type" content="website" />');
    
    if (settings.twitterHandle.isNotEmpty) {
      buffer.writeln('<meta name="twitter:card" content="summary_large_image" />');
      buffer.writeln('<meta name="twitter:site" content="${_escapeHtml(settings.twitterHandle)}" />');
      
      if (settings.ogTitle.isNotEmpty) {
        buffer.writeln('<meta name="twitter:title" content="${_escapeHtml(settings.ogTitle)}" />');
      }
      
      if (settings.ogDescription.isNotEmpty) {
        buffer.writeln('<meta name="twitter:description" content="${_escapeHtml(settings.ogDescription)}" />');
      }
      
      if (settings.ogImage.isNotEmpty) {
        buffer.writeln('<meta name="twitter:image" content="${_escapeHtml(settings.ogImage)}" />');
      }
    }
    
    if (settings.googleSearchConsole.isNotEmpty) {
      buffer.writeln('<meta name="google-site-verification" content="${_escapeHtml(settings.googleSearchConsole)}" />');
    }
    
    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  String generateGoogleAnalyticsScript(String analyticsId) {
    if (analyticsId.isEmpty) return '';
    
    return '''
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=$analyticsId"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '$analyticsId');
</script>
<!-- End Google Analytics -->
''';
  }
}

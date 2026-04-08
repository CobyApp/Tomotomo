import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of reading an X profile page as text (via reader proxy).
class XReadablePage {
  const XReadablePage({required this.text, this.profileImageUrl});

  final String text;
  /// First HTTPS profile image URL found (e.g. pbs.twimg.com), if any.
  final String? profileImageUrl;
}

/// Fetches a public X (Twitter) profile URL as plain text via a reader proxy.
///
/// Uses Jina AI Reader (`r.jina.ai`). X may return login walls; a second request
/// tries image-summary headers. [profileImageUrl] is parsed from markdown/text.
class XProfileReader {
  XProfileReader({Duration? timeout}) : _timeout = timeout ?? const Duration(seconds: 28);

  final Duration _timeout;

  static final RegExp _xHost = RegExp(r'^(?:https?://)?(?:www\.)?(?:x\.com|twitter\.com)/', caseSensitive: false);

  /// Twitter/X CDN profile images (allowlist for suggested avatar).
  static final RegExp twimgProfileImagePattern = RegExp(
    r'https://pbs\.twimg\.com/profile_images/\d+/[A-Za-z0-9_\-]+\.(?:jpg|jpeg|png|webp)(?:\?[^\s]*)?',
    caseSensitive: false,
  );

  /// First profile image URL in [text], or null.
  static String? extractProfileImageUrlFromText(String text) {
    final m = twimgProfileImagePattern.firstMatch(text);
    return m?.group(0)?.trim();
  }

  /// Returns canonical `https://x.com/username` or null if not an X/Twitter profile URL.
  static String? normalizeXUrl(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http')) {
      s = 'https://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null) return null;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    if (host != 'x.com' && host != 'twitter.com' && host != 'mobile.twitter.com' && host != 'mobile.x.com') {
      return null;
    }
    var path = uri.path;
    if (path.isEmpty || path == '/') return null;
    var segments = path.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    // x.com/i/user/123 → keep path (reader may still fail)
    final first = segments.first.toLowerCase();
    const reserved = {'home', 'search', 'explore', 'settings', 'i', 'intent', 'share', 'login', 'signup', 'compose'};
    if (reserved.contains(first)) return null;

    // x.com/user/status/… → profile root only for persona import
    if (segments.length >= 2) {
      final second = segments[1].toLowerCase();
      if (second == 'status' || second == 'photo' || second == 'video' || second == 'communitynotes') {
        segments = [segments[0]];
      }
    }

    return Uri(
      scheme: 'https',
      host: 'x.com',
      pathSegments: segments,
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    ).toString();
  }

  /// GET reader text for [canonicalXUrl] (must be normalized).
  Future<XReadablePage> fetchReadablePage(String canonicalXUrl) async {
    if (!_xHost.hasMatch(canonicalXUrl)) {
      throw FormatException('Not an X/Twitter URL: $canonicalXUrl');
    }
    final encoded = Uri.encodeComponent(canonicalXUrl);
    final readerUri = Uri.parse('https://r.jina.ai/$encoded');

    Future<http.Response> getOnce(Map<String, String> headers) =>
        http.get(readerUri, headers: headers).timeout(_timeout);

    var res = await getOnce(const {'Accept': 'text/plain'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Reader HTTP ${res.statusCode}');
    }
    var body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();

    // Retry with headers that may surface more content / image URLs on dynamic pages.
    if (body.length < 40) {
      res = await getOnce({
        'Accept': 'text/plain',
        'X-With-Images-Summary': 'true',
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
      }
    }

    if (body.length < 40) {
      throw Exception('Page text too short (login wall or block). Paste profile text below.');
    }
    final text = body.length > 14000 ? body.substring(0, 14000) : body;
    final img = extractProfileImageUrlFromText(text);
    return XReadablePage(text: text, profileImageUrl: img);
  }

  /// Backward-compatible: text only.
  Future<String> fetchReadableText(String canonicalXUrl) async {
    final page = await fetchReadablePage(canonicalXUrl);
    return page.text;
  }
}

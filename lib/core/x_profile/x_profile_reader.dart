import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches a public X (Twitter) profile URL as plain text via a reader proxy.
///
/// Uses Jina AI Reader (`r.jina.ai`) to obtain markdown/text from public pages.
/// Results vary: X may return login walls or limited content.
class XProfileReader {
  XProfileReader({Duration? timeout}) : _timeout = timeout ?? const Duration(seconds: 28);

  final Duration _timeout;

  static final RegExp _xHost = RegExp(r'^(?:https?://)?(?:www\.)?(?:x\.com|twitter\.com)/', caseSensitive: false);

  /// Returns canonical `https://x.com/...` path or null if not an X/Twitter URL.
  static String? normalizeXUrl(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http')) {
      s = 'https://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host != 'x.com' && host != 'twitter.com' && host != 'www.x.com' && host != 'www.twitter.com') {
      return null;
    }
    final path = uri.path;
    if (path.isEmpty || path == '/') return null;
    final segments = path.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final first = segments.first.toLowerCase();
    const reserved = {'home', 'search', 'explore', 'settings', 'i', 'intent', 'share', 'login', 'signup', 'compose'};
    if (reserved.contains(first)) return null;
    return Uri(
      scheme: 'https',
      host: 'x.com',
      pathSegments: segments,
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    ).toString();
  }

  /// GET reader markdown for [canonicalXUrl] (must be normalized).
  Future<String> fetchReadableText(String canonicalXUrl) async {
    if (!_xHost.hasMatch(canonicalXUrl)) {
      throw FormatException('Not an X/Twitter URL: $canonicalXUrl');
    }
    final readerUri = Uri.parse('https://r.jina.ai/${Uri.encodeComponent(canonicalXUrl)}');
    final res = await http.get(readerUri, headers: const {'Accept': 'text/plain'}).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Reader HTTP ${res.statusCode}');
    }
    final body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
    if (body.length < 40) {
      throw Exception('Page text too short (login wall or block). Paste profile text below.');
    }
    return body.length > 12000 ? body.substring(0, 12000) : body;
  }
}

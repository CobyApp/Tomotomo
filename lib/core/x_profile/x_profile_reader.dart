import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  XProfileReader({Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 28);

  final Duration _timeout;

  static final RegExp _xHost = RegExp(
    r'^(?:https?://)?(?:www\.)?(?:x\.com|twitter\.com)/',
    caseSensitive: false,
  );

  /// Twitter/X CDN profile images (allowlist for suggested avatar).
  static final RegExp twimgProfileImagePattern = RegExp(
    r'https://pbs\.twimg\.com/profile_images/\d+/[A-Za-z0-9_.\-]+(?:\?[^\s)\]"<>]*)?',
    caseSensitive: false,
  );

  /// First profile image URL in [text], or null.
  static String? extractProfileImageUrlFromText(String text) {
    final m = twimgProfileImagePattern.firstMatch(
      text.replaceAll('&amp;', '&'),
    );
    final raw = m?.group(0)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'name': '400x400'})
        .toString();
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
    if (host != 'x.com' &&
        host != 'twitter.com' &&
        host != 'mobile.twitter.com' &&
        host != 'mobile.x.com') {
      return null;
    }
    var path = uri.path;
    if (path.isEmpty || path == '/') return null;
    var segments = path.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    // x.com/i/user/123 → keep path (reader may still fail)
    final first = segments.first.toLowerCase();
    const reserved = {
      'home',
      'search',
      'explore',
      'settings',
      'i',
      'intent',
      'share',
      'login',
      'signup',
      'compose',
    };
    if (reserved.contains(first)) return null;

    // x.com/user/status/… → profile root only for persona import
    if (segments.length >= 2) {
      final second = segments[1].toLowerCase();
      if (second == 'status' ||
          second == 'photo' ||
          second == 'video' ||
          second == 'communitynotes') {
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

  /// User-facing (Korean) message when the reader cannot fetch the profile.
  static const String _fetchFailedMessage =
      'X에서 불러오지 못했어요. 잠시 후 다시 시도하거나, 직접 만들기로 진행해 주세요.';

  /// A realistic browser User-Agent — bare requests without one often get 403.
  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/125.0.0.0 Safari/537.36';

  /// Base reader headers. Adds `Authorization` when a Jina API key is present,
  /// which raises rate limits and avoids 403s on gated targets.
  Map<String, String> _readerHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'User-Agent': _userAgent,
      'Accept': 'text/plain',
      'X-Return-Format': 'text',
    };
    final apiKey = dotenv.isInitialized ? dotenv.env['JINA_API_KEY'] : null;
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Transient reader statuses worth retrying after a short backoff.
  static bool _isRetryable(int statusCode) =>
      statusCode == 403 ||
      statusCode == 429 ||
      statusCode == 451 ||
      statusCode >= 500;

  /// GET reader text for [canonicalXUrl] (must be normalized).
  Future<XReadablePage> fetchReadablePage(String canonicalXUrl) async {
    if (!_xHost.hasMatch(canonicalXUrl)) {
      throw FormatException('Not an X/Twitter URL: $canonicalXUrl');
    }
    // Jina Reader expects the target URL appended RAW (not percent-encoded), so
    // the request path is `https://r.jina.ai/https://x.com/username`.
    final readerUri = Uri.parse('https://r.jina.ai/$canonicalXUrl');

    Future<http.Response> getOnce(Map<String, String> headers) =>
        http.get(readerUri, headers: headers).timeout(_timeout);

    // Up to 3 attempts total; retry on transient 403/429/451/5xx statuses.
    http.Response? res;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
      }
      try {
        res = await getOnce(_readerHeaders());
      } catch (_) {
        res = null;
        continue;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) break;
      if (!_isRetryable(res.statusCode)) break;
    }
    if (res == null || res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_fetchFailedMessage);
    }
    var body = utf8.decode(res.bodyBytes, allowMalformed: true).trim();

    var profileImageUrl = extractProfileImageUrlFromText(body);

    // Retry when the first rendering omitted image metadata. Some X profiles
    // return full text but hide their avatar unless image summaries are asked for.
    if (body.length < 40 || profileImageUrl == null) {
      final imageRes = await getOnce(
        _readerHeaders(extra: const {'X-With-Images-Summary': 'true'}),
      );
      if (imageRes.statusCode >= 200 && imageRes.statusCode < 300) {
        final imageBody = utf8
            .decode(imageRes.bodyBytes, allowMalformed: true)
            .trim();
        if (imageBody.length >= 40) body = imageBody;
        profileImageUrl = extractProfileImageUrlFromText(imageBody);
      }
    }

    if (body.length < 40) {
      throw Exception(
        'Page text too short (login wall or block). Paste profile text below.',
      );
    }
    profileImageUrl ??= extractProfileImageUrlFromText(body);
    final text = body.length > 14000 ? body.substring(0, 14000) : body;
    return XReadablePage(text: text, profileImageUrl: profileImageUrl);
  }

  /// Backward-compatible: text only.
  Future<String> fetchReadableText(String canonicalXUrl) async {
    final page = await fetchReadablePage(canonicalXUrl);
    return page.text;
  }
}

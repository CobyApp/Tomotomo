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

  /// First path segment (the @username) of a normalized X URL, or null.
  static String? _usernameFromUrl(String canonicalXUrl) {
    final uri = Uri.tryParse(canonicalXUrl);
    if (uri == null) return null;
    final segs = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segs.isEmpty) return null;
    final u = segs.first.trim();
    if (u.isEmpty || u == 'i') return null;
    return u;
  }

  /// Keyless path: X's public syndication (embed) endpoint returns the profile
  /// (name, bio, avatar, recent posts) as JSON — unlike r.jina.ai, it does not
  /// block anonymous access to x.com.
  Future<XReadablePage?> _fetchFromSyndication(String username) async {
    final uri = Uri.parse(
      'https://syndication.twitter.com/srv/timeline-profile/screen-name/$username',
    );
    http.Response res;
    try {
      res = await http
          .get(uri, headers: {'User-Agent': _userAgent, 'Accept': 'text/html'})
          .timeout(_timeout);
    } catch (_) {
      return null;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final html = utf8.decode(res.bodyBytes, allowMalformed: true);
    final m = RegExp(
      r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (m == null) return null;
    dynamic data;
    try {
      data = jsonDecode(m.group(1)!);
    } catch (_) {
      return null;
    }

    String? name, description, location, avatar;
    final tweets = <String>[];
    void walk(dynamic o) {
      if (o is Map) {
        if (o.containsKey('screen_name') && o.containsKey('name')) {
          name ??= (o['name'] as String?)?.trim();
          description ??= (o['description'] as String?)?.trim();
          location ??= (o['location'] as String?)?.trim();
          final img = o['profile_image_url_https'] as String?;
          if (avatar == null && img != null && img.isNotEmpty) avatar = img;
        }
        final ft = o['full_text'];
        if (ft is String && ft.trim().isNotEmpty && tweets.length < 40) {
          tweets.add(ft.trim());
        }
        for (final v in o.values) {
          walk(v);
        }
      } else if (o is List) {
        for (final v in o) {
          walk(v);
        }
      }
    }

    walk(data);
    if ((name == null || name!.isEmpty) &&
        (description == null || description!.isEmpty) &&
        tweets.isEmpty) {
      return null;
    }

    final buf = StringBuffer();
    if (name != null && name!.isNotEmpty) buf.writeln('Name: $name');
    buf.writeln('X: @$username');
    if (description != null && description!.isNotEmpty) {
      buf.writeln('Bio: $description');
    }
    if (location != null && location!.isNotEmpty) {
      buf.writeln('Location: $location');
    }
    if (tweets.isNotEmpty) {
      buf.writeln('\nRecent posts:');
      for (final t in tweets) {
        buf.writeln('- ${t.replaceAll('\n', ' ').trim()}');
      }
    }
    var text = buf.toString().trim();
    if (text.length < 20) return null;
    if (text.length > 14000) text = text.substring(0, 14000);

    String? avatarUrl;
    if (avatar != null && avatar!.isNotEmpty) {
      // `_normal.jpg` → `_400x400.jpg` for a higher-res avatar.
      avatarUrl = avatar!.replaceAll(RegExp(r'_normal\.'), '_400x400.');
    }
    return XReadablePage(text: text, profileImageUrl: avatarUrl);
  }

  /// GET reader text for [canonicalXUrl] (must be normalized).
  Future<XReadablePage> fetchReadablePage(String canonicalXUrl) async {
    if (!_xHost.hasMatch(canonicalXUrl)) {
      throw FormatException('Not an X/Twitter URL: $canonicalXUrl');
    }

    // 1) Keyless primary path: X syndication embed endpoint.
    final username = _usernameFromUrl(canonicalXUrl);
    if (username != null) {
      final syndicated = await _fetchFromSyndication(username);
      if (syndicated != null) return syndicated;
    }

    // 2) Fallback: Jina Reader. It blocks anonymous x.com access, so this
    // mostly helps when a JINA_API_KEY is configured. Jina expects the target
    // URL appended RAW: `https://r.jina.ai/https://x.com/username`.
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

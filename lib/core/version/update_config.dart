import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of comparing the installed build against the remote gate config.
enum UpdateStatus {
  /// Up to date (or newer) — no prompt.
  ok,

  /// A newer build exists — show a dismissible "recommended update" banner.
  recommended,

  /// Below the minimum supported build — hard-block with a forced update.
  forced,
}

/// Remote update-gate config, hosted as `version.json` on GitHub Pages.
class RemoteVersionConfig {
  const RemoteVersionConfig({
    required this.minBuild,
    required this.latestBuild,
    this.storeUrl,
  });

  /// Installed builds below this are force-updated (hard block).
  final int minBuild;

  /// Installed builds below this (but >= [minBuild]) get a recommended update.
  final int latestBuild;

  /// App Store URL to send users to. Null/empty hides the store button.
  final String? storeUrl;

  /// Parses the remote JSON. Returns null when required fields are missing or
  /// malformed, so a bad config can never accidentally lock users out.
  static RemoteVersionConfig? tryParse(Object? decoded) {
    if (decoded is! Map) return null;
    final min = _asInt(decoded['min_build']);
    final latest = _asInt(decoded['latest_build']);
    if (min == null || latest == null) return null;
    final url = decoded['store_url'];
    return RemoteVersionConfig(
      minBuild: min,
      latestBuild: latest,
      storeUrl: (url is String && url.trim().isNotEmpty) ? url.trim() : null,
    );
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// Pure comparison — [currentBuild] vs the remote thresholds.
UpdateStatus evaluateUpdate({
  required int currentBuild,
  required RemoteVersionConfig config,
}) {
  if (currentBuild < config.minBuild) return UpdateStatus.forced;
  if (currentBuild < config.latestBuild) return UpdateStatus.recommended;
  return UpdateStatus.ok;
}

/// Best-effort fetch of the remote config. Returns null on ANY failure
/// (offline, timeout, non-200, bad JSON) so the app never blocks when it
/// cannot reach the network — offline users pass straight through.
Future<RemoteVersionConfig?> fetchVersionConfig(
  Uri url, {
  Duration timeout = const Duration(seconds: 4),
  http.Client? client,
}) async {
  final http.Client c = client ?? http.Client();
  try {
    final res = await c.get(url).timeout(timeout);
    if (res.statusCode != 200) return null;
    return RemoteVersionConfig.tryParse(jsonDecode(res.body));
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Hosts the update button is allowed to open.
const Set<String> _storeHosts = {
  'apps.apple.com',
  'itunes.apple.com',
  'play.google.com',
};

/// Whether [storeUrl] is a real store listing.
///
/// The URL arrives in a remote JSON file. Unvalidated, a tampered file could pair
/// a forced-update screen the user cannot dismiss with a button that opens any
/// https page or registered scheme — a phishing prompt carrying the app's own
/// credibility.
bool isAllowedStoreUrl(String? storeUrl) {
  final raw = storeUrl?.trim() ?? '';
  if (raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'itms-apps' || scheme == 'market') return true;
  return scheme == 'https' && _storeHosts.contains(uri.host.toLowerCase());
}

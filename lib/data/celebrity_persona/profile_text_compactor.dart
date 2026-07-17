/// Reduces scraped social-profile text to a predictable on-device prompt size.
///
/// Scraped pages contain repeated navigation, image markdown, and long tracking
/// URLs. Keeping those wastes the model's limited context window without
/// helping it infer the profile's tone.
String compactProfileText(String rawText, {int maxRunes = 2800}) {
  if (maxRunes <= 0) return '';

  final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final seen = <String>{};
  final kept = <String>[];

  for (final rawLine in normalized.split('\n')) {
    var line = rawLine.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.isEmpty) continue;

    line = line.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(https?://[^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    line = line.replaceAll(RegExp(r'https?://\S+'), '').trim();
    if (line.isEmpty || RegExp(r'^!\[.*\]$').hasMatch(line)) continue;

    line = _takeRunes(line, 320);
    final dedupeKey = line.toLowerCase();
    if (!seen.add(dedupeKey)) continue;
    kept.add(line);
  }

  return _takeRunes(kept.join('\n'), maxRunes).trim();
}

String _takeRunes(String value, int limit) {
  final runes = value.runes;
  if (runes.length <= limit) return value;
  return String.fromCharCodes(runes.take(limit));
}

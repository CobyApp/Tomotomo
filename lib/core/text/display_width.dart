import 'package:characters/characters.dart';

/// Approximate rendered width of [text] in half-widths.
///
/// CJK ideographs, kana, hangul, fullwidth forms and emoji take about twice the
/// width of a Latin letter, so budgeting by character COUNT clips the two
/// alphabets unequally: 28 characters of Japanese is roughly 56 Latin letters
/// wide, which means a count that fits Japanese cuts English off less than
/// halfway.
int displayWidth(String text) {
  var width = 0;
  for (final cluster in text.characters) {
    width += _clusterWidth(cluster);
  }
  return width;
}

/// Truncates [text] to [maxHalfWidths] of rendered width — and to [maxRunes]
/// characters when given, for fields that also enforce a character cap — adding
/// [ellipsis] when anything was dropped.
///
/// Walks grapheme clusters, not code units or runes, so a surrogate pair or an
/// emoji ZWJ sequence (👩‍💻) can never be cut into broken halves.
String clampToDisplayWidth(
  String text,
  int maxHalfWidths, {
  int? maxRunes,
  String ellipsis = '…',
}) {
  final overWidth = displayWidth(text) > maxHalfWidths;
  final overCount = maxRunes != null && text.characters.length > maxRunes;
  if (!overWidth && !overCount) return text;

  // With no room for content plus the ellipsis, fill the budget with content
  // rather than returning an ellipsis that itself overflows.
  final ellipsisWidth = displayWidth(ellipsis);
  final withEllipsis = maxHalfWidths > ellipsisWidth;
  final widthBudget = withEllipsis ? maxHalfWidths - ellipsisWidth : maxHalfWidths;
  final countBudget = maxRunes == null
      ? null
      : (withEllipsis ? maxRunes - ellipsis.characters.length : maxRunes);

  final kept = StringBuffer();
  var width = 0;
  var count = 0;
  for (final cluster in text.characters) {
    final nextWidth = width + _clusterWidth(cluster);
    if (nextWidth > widthBudget) break;
    if (countBudget != null && count + 1 > countBudget) break;
    kept.write(cluster);
    width = nextWidth;
    count++;
  }
  return withEllipsis ? '$kept$ellipsis' : kept.toString();
}

/// Width of one grapheme cluster. Combining marks ride along with their base, so
/// the leading rune decides.
int _clusterWidth(String cluster) {
  final first = cluster.runes.first;
  return _isWide(first) ? 2 : 1;
}

/// East Asian Wide / Fullwidth ranges plus emoji, enough for the scripts and
/// symbols this app shows.
bool _isWide(int rune) =>
    (rune >= 0x1100 && rune <= 0x115F) || // hangul jamo
    (rune >= 0x2600 && rune <= 0x27BF) || // misc symbols, dingbats (✅ ⭐ ❤)
    (rune >= 0x2E80 && rune <= 0x303E) || // CJK radicals, punctuation
    (rune >= 0x3041 && rune <= 0x33FF) || // kana, compat jamo, CJK squared
    (rune >= 0x3400 && rune <= 0x4DBF) || // CJK ext A
    (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK unified
    (rune >= 0xA000 && rune <= 0xA4CF) || // Yi
    (rune >= 0xAC00 && rune <= 0xD7A3) || // hangul syllables
    (rune >= 0xF900 && rune <= 0xFAFF) || // CJK compatibility
    (rune >= 0xFE30 && rune <= 0xFE6F) || // CJK compat forms
    (rune >= 0xFF00 && rune <= 0xFF60) || // fullwidth forms
    (rune >= 0xFFE0 && rune <= 0xFFE6) ||
    (rune >= 0x1F1E6 && rune <= 0x1F1FF) || // regional indicators (flags)
    (rune >= 0x1F200 && rune <= 0x1F2FF) || // enclosed CJK supplement (🈯)
    (rune >= 0x1F300 && rune <= 0x1FAFF) || // emoji
    (rune >= 0x20000 && rune <= 0x3FFFD); // CJK ext B and beyond

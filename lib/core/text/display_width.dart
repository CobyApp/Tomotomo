/// Approximate rendered width of [text] in half-widths.
///
/// CJK ideographs, kana, hangul and fullwidth forms take about twice the width
/// of a Latin letter, so budgeting by character COUNT clips the two alphabets
/// unequally: 28 characters of Japanese is roughly 56 Latin letters wide, which
/// means a count that fits Japanese cuts English off less than halfway.
int displayWidth(String text) {
  var width = 0;
  for (final rune in text.runes) {
    width += _isWide(rune) ? 2 : 1;
  }
  return width;
}

/// Truncates [text] to [maxHalfWidths] of rendered width, appending [ellipsis]
/// when anything was dropped.
///
/// Iterates runes, never UTF-16 code units, so an emoji or any other surrogate
/// pair can't be split into two broken halves.
String clampToDisplayWidth(
  String text,
  int maxHalfWidths, {
  String ellipsis = '…',
}) {
  if (displayWidth(text) <= maxHalfWidths) return text;
  final budget = maxHalfWidths - displayWidth(ellipsis);
  final kept = <int>[];
  var width = 0;
  for (final rune in text.runes) {
    final next = width + (_isWide(rune) ? 2 : 1);
    if (next > budget) break;
    kept.add(rune);
    width = next;
  }
  return '${String.fromCharCodes(kept)}$ellipsis';
}

/// East Asian Wide / Fullwidth ranges, enough for the scripts this app shows.
bool _isWide(int rune) =>
    (rune >= 0x1100 && rune <= 0x115F) || // hangul jamo
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
    (rune >= 0x1F300 && rune <= 0x1FAFF); // emoji

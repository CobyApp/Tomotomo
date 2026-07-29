import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';

/// Offline local RAG: pulls the learner's saved vocabulary and relevant older
/// conversation turns that relate to the current message, so the friend can
/// "remember" them. Retrieval is lexical (token + CJK character-bigram overlap)
/// — no embedding model, no network. Returns a compact context block (or '').
class LocalRagRetriever {
  LocalRagRetriever(this._wordbook, this._chat);

  final SavedExpressionRepository _wordbook;
  final ChatRepository _chat;

  static const int _maxWords = 4;
  static const int _maxPastTurns = 3;
  static const int _recentTurnsInLiveContext = 6;
  static const int _maxContextChars = 900;

  Future<String> retrieveContext({
    required Character character,
    required String userMessage,
  }) async {
    final query = _terms(userMessage);
    if (query.isEmpty) return '';
    final buf = StringBuffer();

    // 1) Saved vocabulary the learner has kept, relevant to this message.
    try {
      final lang = character.defaultNotebookLangForVocabSave;
      final words = await _wordbook.listForCurrentUser(notebookLang: lang);
      final ranked = _rank(
        words,
        (w) => '${w.content ?? ''} ${w.translation ?? ''}',
        query,
      ).take(_maxWords).toList();
      if (ranked.isNotEmpty) {
        buf.writeln(
          'SAVED VOCABULARY THE LEARNER KNOWS (use naturally when relevant):',
        );
        for (final w in ranked) {
          final gloss = (w.translation != null && w.translation!.trim().isNotEmpty)
              ? ' (${_clip(w.translation!, 60)})'
              : '';
          buf.writeln('- ${w.content ?? ''}$gloss');
        }
        buf.writeln();
      }
    } catch (_) {
      // Best-effort; retrieval never blocks a reply.
    }

    // 2) Older conversation turns (beyond the live window) relevant now —
    //    gives cross-session memory.
    try {
      final msgs = await _chat.getMessages(character);
      final older = msgs.length > _recentTurnsInLiveContext
          ? msgs.sublist(0, msgs.length - _recentTurnsInLiveContext)
          : const <ChatMessage>[];
      final ranked = _rank(
        older,
        (m) => m.content,
        query,
      ).take(_maxPastTurns).toList();
      if (ranked.isNotEmpty) {
        buf.writeln(
          'RELEVANT PAST CONVERSATION (for continuity; do not repeat verbatim):',
        );
        for (final m in ranked) {
          final who = m.role == 'user' ? 'User' : 'You';
          buf.writeln('- $who: ${_clip(m.content, 120)}');
        }
      }
    } catch (_) {}

    var out = buf.toString().trim();
    if (out.length > _maxContextChars) out = out.substring(0, _maxContextChars);
    return out;
  }

  /// Ranks [items] by lexical overlap with [query], descending; drops zeros.
  ///
  /// Scored as overlap² / term-count so a long stored item cannot outrank a
  /// short, closely-matching one purely by having more text to collide with.
  List<T> _rank<T>(
    List<T> items,
    String Function(T) textOf,
    Set<String> query,
  ) {
    final scored = <(T, double)>[];
    for (final item in items) {
      final terms = _terms(textOf(item));
      if (terms.isEmpty) continue;
      final overlap = terms.intersection(query).length;
      if (overlap > 0) {
        scored.add((item, overlap * overlap / terms.length));
      }
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  /// Lexical terms: lowercased whitespace tokens (len ≥ 2), plus character
  /// bigrams — but only across CJK, never across Latin.
  ///
  /// Bigrams stand in for word segmentation in Japanese, Chinese and Korean,
  /// which do not separate words with spaces. Applied to Latin they are letter
  /// pairs: "I love studying Japanese" produced 19 of them (il lo ov ve es st …),
  /// so `hello — greeting` matched on lo/in/ng with no relation to the message
  /// and could be retrieved as vocabulary the learner "knows". English was the
  /// only language where retrieval was mostly noise.
  static Set<String> _terms(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.isEmpty) return const {};
    final terms = <String>{};
    for (final tok in s.split(RegExp(r'[\s\p{P}]+', unicode: true))) {
      if (tok.length >= 2) terms.add(tok);
    }
    final compact = s.replaceAll(RegExp(r'\s+'), '');
    final runes = compact.runes.toList();
    for (var i = 0; i + 1 < runes.length; i++) {
      if (_isCjk(runes[i]) && _isCjk(runes[i + 1])) {
        terms.add(String.fromCharCodes([runes[i], runes[i + 1]]));
      }
    }
    return terms;
  }

  /// Han, kana or hangul — the scripts written without spaces between words.
  static bool _isCjk(int rune) =>
      (rune >= 0x3040 && rune <= 0x30FF) ||
      (rune >= 0x3400 && rune <= 0x4DBF) ||
      (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      (rune >= 0xF900 && rune <= 0xFAFF);

  static String _clip(String s, int max) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= max ? t : '${t.substring(0, max - 1)}…';
  }
}

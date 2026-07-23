import 'package:flutter/material.dart';

/// PAPER-CARTOON tokens. Two schemes (light/dark); components read [PaperColors]
/// from the active [Theme] extension so they adapt to mode automatically.
@immutable
class PaperColors extends ThemeExtension<PaperColors> {
  const PaperColors({
    required this.paperBg,
    required this.card,
    required this.cardEdge,
    required this.hardShadow,
    required this.softShadow,
    required this.ink,
    required this.inkSoft,
    required this.coral,
    required this.coralDeep,
    required this.tape,
    required this.stampBlue,
    required this.grain,
  });

  final Color paperBg, card, cardEdge, hardShadow, softShadow;
  final Color ink, inkSoft, coral, coralDeep, tape, stampBlue, grain;

  // Y2K BUBBLE KITSCH (matching / oshikore) — pastel gradient world with
  // sticker borders: a thick deep-purple ink outline + a HARD offset shadow
  // (no blur). Token names kept: coral = hotpink, coralDeep = purple,
  // stampBlue = cyan, cardEdge/hardShadow = ink.
  static const light = PaperColors(
    paperBg: Color(0xFFF7ECFF),
    card: Color(0xFFFFFFFF),
    cardEdge: Color(0xFF3A1D5C), // ink — thick sticker border
    hardShadow: Color(0xFF3A1D5C), // ink — hard offset shadow
    softShadow: Color(0x143A1D5C),
    ink: Color(0xFF3A1D5C),
    inkSoft: Color(0xFF7A5A93),
    coral: Color(0xFFFF4FD8), // hotpink
    coralDeep: Color(0xFF9B4DFF), // purple
    tape: Color(0xB3FFE24D), // lemon
    stampBlue: Color(0xFF46E3E6), // cyan
    grain: Color(0x00000000),
  );

  static const dark = PaperColors(
    paperBg: Color(0xFF241633),
    card: Color(0xFF31234A),
    cardEdge: Color(0xFF0E0620),
    hardShadow: Color(0xFF0E0620),
    softShadow: Color(0x40000000),
    ink: Color(0xFFF7ECFF),
    inkSoft: Color(0xFFC7A9E0),
    coral: Color(0xFFFF6FE0),
    coralDeep: Color(0xFFB477FF),
    tape: Color(0xB3FFE24D),
    stampBlue: Color(0xFF6BEDEF),
    grain: Color(0x00000000),
  );

  @override
  PaperColors copyWith({Color? paperBg, Color? card, Color? cardEdge, Color? hardShadow, Color? softShadow, Color? ink, Color? inkSoft, Color? coral, Color? coralDeep, Color? tape, Color? stampBlue, Color? grain}) {
    return PaperColors(
      paperBg: paperBg ?? this.paperBg,
      card: card ?? this.card,
      cardEdge: cardEdge ?? this.cardEdge,
      hardShadow: hardShadow ?? this.hardShadow,
      softShadow: softShadow ?? this.softShadow,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      coral: coral ?? this.coral,
      coralDeep: coralDeep ?? this.coralDeep,
      tape: tape ?? this.tape,
      stampBlue: stampBlue ?? this.stampBlue,
      grain: grain ?? this.grain,
    );
  }

  @override
  PaperColors lerp(ThemeExtension<PaperColors>? other, double t) {
    if (other is! PaperColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaperColors(
      paperBg: c(paperBg, other.paperBg), card: c(card, other.card),
      cardEdge: c(cardEdge, other.cardEdge), hardShadow: c(hardShadow, other.hardShadow),
      softShadow: c(softShadow, other.softShadow), ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft), coral: c(coral, other.coral),
      coralDeep: c(coralDeep, other.coralDeep), tape: c(tape, other.tape),
      stampBlue: c(stampBlue, other.stampBlue), grain: c(grain, other.grain),
    );
  }
}

/// Convenience accessor: `context.paper`.
extension PaperColorsX on BuildContext {
  PaperColors get paper => Theme.of(this).extension<PaperColors>() ?? PaperColors.light;
}

abstract final class PaperRadii {
  static const card = 18.0;
  static const button = 15.0;
  static const pill = 999.0;
  static const polaroid = 3.0;
}

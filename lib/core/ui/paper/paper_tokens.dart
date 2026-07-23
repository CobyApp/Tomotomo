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

  // Y2K vaporwave — pastel neon (hot pink / cyan / purple), glassy surfaces.
  // Token names are kept (coral = pink accent, stampBlue = cyan) so every
  // consumer re-themes automatically.
  static const light = PaperColors(
    paperBg: Color(0xFFF6ECFF),
    card: Color(0xFFFDFAFF),
    cardEdge: Color(0xFFE7CDF7),
    hardShadow: Color(0xFFEAD6FA),
    softShadow: Color(0x26A060D0),
    ink: Color(0xFF32245F),
    inkSoft: Color(0xFF6E5C9E),
    coral: Color(0xFFF5459B),
    coralDeep: Color(0xFFC81E8C),
    tape: Color(0x8067E8FF),
    stampBlue: Color(0xFF12B5CE),
    grain: Color(0x0FA060D0),
  );

  static const dark = PaperColors(
    paperBg: Color(0xFF160E30),
    card: Color(0xFF241843),
    cardEdge: Color(0xFF3C2A6B),
    hardShadow: Color(0xFF0E0822),
    softShadow: Color(0x59000000),
    ink: Color(0xFFF1EAFF),
    inkSoft: Color(0xFFB9A8E6),
    coral: Color(0xFFFF7BC6),
    coralDeep: Color(0xFFFF4FB0),
    tape: Color(0x6640E0FF),
    stampBlue: Color(0xFF54E6F7),
    grain: Color(0x14FFFFFF),
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

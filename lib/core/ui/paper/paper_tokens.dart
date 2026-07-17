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

  static const light = PaperColors(
    paperBg: Color(0xFFF7EDE0),
    card: Color(0xFFFFFDF8),
    cardEdge: Color(0xFFEFE2CE),
    hardShadow: Color(0xFFE8D9C1),
    softShadow: Color(0x24907850),
    ink: Color(0xFF4A3B32),
    inkSoft: Color(0xFF9C7B62),
    coral: Color(0xFFC9563D),
    coralDeep: Color(0xFFA8442E),
    tape: Color(0x80E6B48C),
    stampBlue: Color(0xFF3AA6B8),
    grain: Color(0x0DA07850),
  );

  static const dark = PaperColors(
    paperBg: Color(0xFF241E1A),
    card: Color(0xFF2E2723),
    cardEdge: Color(0xFF3A312B),
    hardShadow: Color(0xFF1C1714),
    softShadow: Color(0x40000000),
    ink: Color(0xFFF2E7D8),
    inkSoft: Color(0xFFB79A82),
    coral: Color(0xFFE9765C),
    coralDeep: Color(0xFFC85B44),
    tape: Color(0x66C79A72),
    stampBlue: Color(0xFF5FC3D4),
    grain: Color(0x0DFFFFFF),
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

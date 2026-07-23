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

  // Soft CYBERPUNK / otaku — a clean, light UI with restrained neon accents
  // (magenta + cyan) and a hint of purple, not a dark neon-blast. Token names
  // are kept (coral = magenta accent, stampBlue = cyan) so every consumer
  // re-themes automatically.
  static const light = PaperColors(
    paperBg: Color(0xFFF0F1FA),
    card: Color(0xFFFDFDFF),
    cardEdge: Color(0xFFD9DDF0),
    hardShadow: Color(0xFFDBDFF2),
    softShadow: Color(0x1A5B6BD0),
    ink: Color(0xFF1E1B3A),
    inkSoft: Color(0xFF6B6699),
    coral: Color(0xFFF6339A),
    coralDeep: Color(0xFFD01A7E),
    tape: Color(0x5500C2D8),
    stampBlue: Color(0xFF0098C4),
    grain: Color(0x0E5B6BD0),
  );

  static const dark = PaperColors(
    paperBg: Color(0xFF14122A),
    card: Color(0xFF1F1B3D),
    cardEdge: Color(0xFF322A5C),
    hardShadow: Color(0xFF0C0A1C),
    softShadow: Color(0x66000000),
    ink: Color(0xFFEDE9FF),
    inkSoft: Color(0xFFA99AD8),
    coral: Color(0xFFFF5CA8),
    coralDeep: Color(0xFFFF3D96),
    tape: Color(0x5522E7FF),
    stampBlue: Color(0xFF35D6F0),
    grain: Color(0x12FFFFFF),
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

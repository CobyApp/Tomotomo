import 'package:flutter/material.dart';
import 'holo_tokens.dart';

/// Display text with an RGB channel-split glitch look: three offset colored
/// copies behind a solid ink copy. Use for the app name and key headers only.
class GlitchText extends StatelessWidget {
  const GlitchText(this.text, {super.key, this.style, this.offset = 2});

  final String text;
  final TextStyle? style;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final base = (style ??
            Theme.of(context).textTheme.titleLarge ??
            const TextStyle())
        .copyWith(fontWeight: FontWeight.w900, color: Holo.inkPlum);
    Widget layer(Color c, Offset d) => Transform.translate(
          offset: d,
          child: Text(text, style: base.copyWith(color: c)),
        );
    return Stack(
      alignment: Alignment.center,
      children: [
        layer(Holo.glitchR, Offset(-offset, 0)),
        layer(Holo.glitchG, Offset(offset, 0)),
        layer(Holo.glitchB, Offset(0, offset)),
        Text(text, style: base),
      ],
    );
  }
}

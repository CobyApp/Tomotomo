import 'package:flutter/material.dart';

import '../../core/ui/paper/paper_bottom_sheet.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/chat_background/chat_background.dart';
import '../../data/chat_background/chat_background_presets.dart';
import '../../data/chat_background/chat_background_store.dart';
import '../locale/l10n_context.dart';

/// Opens the paper-styled per-room background picker as a bottom sheet.
///
/// Shows a live preview (mini chat mock) that updates in real time as the user
/// changes the selected preset or intensity. On "Apply" it persists the choice
/// via [store] for [characterId] and returns the saved [ChatBackground];
/// returns `null` if dismissed without applying.
Future<ChatBackground?> openChatBackgroundPicker(
  BuildContext context, {
  required String characterId,
  required ChatBackground current,
  required ChatBackgroundStore store,
}) {
  return showPaperSheet<ChatBackground>(
    context,
    builder: (_) => _ChatBackgroundPickerBody(
      characterId: characterId,
      initial: current,
      store: store,
    ),
  );
}

class _ChatBackgroundPickerBody extends StatefulWidget {
  const _ChatBackgroundPickerBody({
    required this.characterId,
    required this.initial,
    required this.store,
  });

  final String characterId;
  final ChatBackground initial;
  final ChatBackgroundStore store;

  @override
  State<_ChatBackgroundPickerBody> createState() =>
      _ChatBackgroundPickerBodyState();
}

class _ChatBackgroundPickerBodyState extends State<_ChatBackgroundPickerBody> {
  late String _presetId = widget.initial.presetId;
  late double _intensity = widget.initial.intensity;

  ChatBackground get _draft =>
      ChatBackground(presetId: _presetId, intensity: _intensity);

  Future<void> _apply() async {
    final bg = _draft;
    await widget.store.set(widget.characterId, bg);
    if (!mounted) return;
    Navigator.of(context).pop(bg);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('chatBgTitle'),
            style: cuteDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 14),
          _PreviewCard(background: _draft),
          const SizedBox(height: 18),
          _PresetSwatchRow(
            selectedId: _presetId,
            intensity: _intensity,
            onSelected: (id) => setState(() => _presetId = id),
          ),
          const SizedBox(height: 18),
          _IntensitySlider(
            value: _intensity,
            onChanged: (v) => setState(() => _intensity = v),
          ),
          const SizedBox(height: 20),
          PaperButton(
            label: context.tr('chatBgApply'),
            icon: Icons.check_rounded,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}

/// Live preview: a mini chat mock rendered over the current selection.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.background});

  final ChatBackground background;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PaperRadii.card),
      child: DecoratedBox(
        decoration: chatBackgroundDecoration(context, background).copyWith(
          border: Border.all(color: p.cardEdge),
          borderRadius: BorderRadius.circular(PaperRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: p.coral.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr('chatBgPreviewName').characters.first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.coral,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('chatBgPreviewName'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MiniBubble(isUser: false),
              const SizedBox(height: 8),
              _MiniBubble(isUser: true),
              const SizedBox(height: 8),
              _MiniBubble(isUser: false, short: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single sample bubble mirroring [ChatBubble]'s coral/cream styling.
class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.isUser, this.short = false});

  final bool isUser;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isUser ? 14 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 14),
    );
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          width: short ? 96 : 150,
          height: 22,
          decoration: BoxDecoration(
            color: isUser ? p.coral : p.card,
            borderRadius: radius,
            border: isUser ? null : Border.all(color: p.cardEdge),
          ),
        ),
      ],
    );
  }
}

/// Row of tappable preset swatches; the selected one gets a coral ring.
class _PresetSwatchRow extends StatelessWidget {
  const _PresetSwatchRow({
    required this.selectedId,
    required this.intensity,
    required this.onSelected,
  });

  final String selectedId;
  final double intensity;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final preset in chatBackgroundPresets)
          _Swatch(
            label: context.tr(preset.labelKey),
            // Preview each swatch at the currently selected intensity.
            fill: chatBackgroundStops(
              context,
              ChatBackground(presetId: preset.id, intensity: intensity),
            ).top,
            selected: preset.id == selectedId,
            ring: p.coral,
            edge: p.cardEdge,
            labelColor: p.inkSoft,
            onTap: () => onSelected(preset.id),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.fill,
    required this.selected,
    required this.ring,
    required this.edge,
    required this.labelColor,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final bool selected;
  final Color ring;
  final Color edge;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? ring : edge,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 20, color: ring)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coral-themed intensity (농도) slider, 0–100%.
class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('chatBgIntensity'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.coralDeep,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: p.coral,
            inactiveTrackColor: p.cardEdge,
            thumbColor: p.coralDeep,
            overlayColor: p.coral.withValues(alpha: 0.15),
            trackHeight: 5,
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/image/image_crop.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/chat_background/chat_background.dart';
import '../../data/chat_background/chat_background_presets.dart';
import '../../data/chat_background/chat_background_store.dart';
import '../locale/l10n_context.dart';

/// Opens the paper-styled per-room background picker as a full-screen page.
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
  return Navigator.of(context).push<ChatBackground>(
    MaterialPageRoute<ChatBackground>(
      builder: (_) => PaperScaffold(
        title: context.tr('chatBgTitle'),
        transparentBackground: false,
        body: _ChatBackgroundPickerBody(
          characterId: characterId,
          initial: current,
          store: store,
        ),
      ),
    ),
  );
}

/// Copies a picked background image into the app documents dir, returns path.
Future<String> _copyBgToAppDir(File src) async {
  final dir = await getApplicationDocumentsDirectory();
  final bgDir = Directory('${dir.path}/chat_backgrounds');
  if (!await bgDir.exists()) await bgDir.create(recursive: true);
  final ext = src.path.split('.').last;
  final dest = File(
    '${bgDir.path}/bg_${src.hashCode}_${src.lengthSync()}.$ext',
  );
  await src.copy(dest.path);
  return dest.path;
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
  late String? _imagePath = widget.initial.imagePath;
  bool _picking = false;

  ChatBackground get _draft => ChatBackground(
    presetId: _presetId,
    intensity: _intensity,
    imagePath: _imagePath,
  );

  Future<void> _pickBgImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (x == null || !mounted) return;
      final cropped = await cropImagePath(x.path);
      if (cropped == null || !mounted) return;
      final stored = await _copyBgToAppDir(File(cropped));
      if (!mounted) return;
      setState(() => _imagePath = stored);
    } catch (_) {
      // Best-effort; leave the current selection unchanged on failure.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewCard(background: _draft),
          const SizedBox(height: 18),
          _PresetSwatchRow(
            selectedId: _imagePath == null ? _presetId : null,
            intensity: _intensity,
            // Choosing a color preset clears any custom photo.
            onSelected: (id) => setState(() {
              _presetId = id;
              _imagePath = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _picking ? null : _pickBgImage,
                  icon: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: PaperLoading(size: 6),
                        )
                      : const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(context.tr('chatBgFromGallery')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.ink,
                    backgroundColor: p.card,
                    side: BorderSide(color: p.ink, width: 2),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _imagePath = null),
                  icon: Icon(Icons.close_rounded, color: p.inkSoft),
                  tooltip: context.tr('chatBgRemovePhoto'),
                ),
              ],
            ],
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
    return Container(
      // Fixed height: the default background renders via PaperBackground's
      // StackFit.expand, which needs a bounded height inside this scroll view.
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: p.ink, width: 2.5),
        borderRadius: BorderRadius.circular(PaperRadii.card),
        boxShadow: [
          BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: buildChatBackground(
        context,
        background,
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

  final String? selectedId;
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
            // Preview each swatch at a fixed, representative opacity so the
            // colors are always distinguishable regardless of the slider.
            fill: chatBackgroundStops(
              context,
              ChatBackground(presetId: preset.id, intensity: 0.8),
            ).top,
            selected: preset.id == selectedId,
            ring: p.coral,
            edge: p.ink,
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? ring : edge,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: edge,
                  offset: Offset(selected ? 1 : 2, selected ? 1 : 2),
                ),
              ],
            ),
            child: selected
                ? Container(
                    decoration: BoxDecoration(
                      color: ring,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  )
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

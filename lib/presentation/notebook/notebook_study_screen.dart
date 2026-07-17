import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/holo/glitch_text.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../core/ui/ui.dart';
import '../../domain/entities/saved_expression.dart';
import '../locale/l10n_context.dart';

class NotebookStudyScreen extends StatefulWidget {
  const NotebookStudyScreen({
    super.key,
    required this.items,
    required this.notebookLanguage,
  });

  final List<SavedExpression> items;
  final String notebookLanguage;

  @override
  State<NotebookStudyScreen> createState() => _NotebookStudyScreenState();
}

class _NotebookStudyScreenState extends State<NotebookStudyScreen> {
  late List<SavedExpression> _cards;
  int _index = 0;
  int _known = 0;
  int _review = 0;
  bool _revealed = false;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cards = List<SavedExpression>.of(widget.items)..shuffle();
    _index = 0;
    _known = 0;
    _review = 0;
    _revealed = false;
    _complete = _cards.isEmpty;
  }

  void _restart() => setState(_reset);

  void _reveal() {
    if (!_revealed && !_complete) setState(() => _revealed = true);
  }

  void _answer({required bool known}) {
    if (!_revealed || _complete) return;
    setState(() {
      if (known) {
        _known++;
      } else {
        _review++;
      }
      if (_index >= _cards.length - 1) {
        _complete = true;
      } else {
        _index++;
        _revealed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('notebookStudyTitle'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH,
            AppSpacing.pageTop,
            AppSpacing.pageH,
            AppSpacing.pageBottom,
          ),
          child: _complete ? _buildSummary(context) : _buildSession(context),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final progress = (_index + 1) / _cards.length;
    final item = _cards[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.tr('notebookStudyProgress'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Holo.inkPlumSoft),
            ),
            const Spacer(),
            Text(
              '${_index + 1} / ${_cards.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Holo.inkPlum,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _StudyCard(
                key: ValueKey('${item.id}_$_revealed'),
                item: item,
                revealed: _revealed,
                notebookLanguage: widget.notebookLanguage,
                onTap: _reveal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!_revealed)
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _reveal,
              icon: const Icon(Icons.touch_app_rounded),
              label: Text(context.tr('notebookStudyReveal')),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _answer(known: false),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('notebookStudyAgain')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _answer(known: true),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.tr('notebookStudyKnow')),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final total = math.max(1, _cards.length);
    final percent = ((_known / total) * 100).round();
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: Holo.holoGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: Holo.floatingShadow,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            GlitchText(
              context.tr('notebookStudyComplete'),
              style: Theme.of(context).textTheme.headlineSmall,
              offset: 1.1,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('notebookStudyScore', params: {'percent': '$percent'}),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Holo.inkPlumSoft),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ResultTile(
                    icon: Icons.refresh_rounded,
                    value: _review,
                    label: context.tr('notebookStudyAgain'),
                    color: Holo.lilac,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResultTile(
                    icon: Icons.check_rounded,
                    value: _known,
                    label: context.tr('notebookStudyKnow'),
                    color: Holo.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(context.tr('notebookStudyRestart')),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('notebookStudyClose')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    super.key,
    required this.item,
    required this.revealed,
    required this.notebookLanguage,
    required this.onTap,
  });

  final SavedExpression item;
  final bool revealed;
  final String notebookLanguage;
  final VoidCallback onTap;

  (String?, String) get _translationParts {
    final translation = item.translation?.trim() ?? '';
    const separator = ' — ';
    final separatorIndex = translation.indexOf(separator);
    if (separatorIndex < 0) return (null, translation);
    final reading = translation.substring(0, separatorIndex).trim();
    final meaning = translation
        .substring(separatorIndex + separator.length)
        .trim();
    return (reading.isEmpty ? null : reading, meaning);
  }

  @override
  Widget build(BuildContext context) {
    final word = item.content?.trim().isNotEmpty == true
        ? item.content!.trim()
        : '—';
    final (reading, meaning) = _translationParts;
    final note = item.explanation?.trim();

    return Semantics(
      button: !revealed,
      label: revealed ? word : context.tr('notebookStudyReveal'),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520, minHeight: 330),
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Holo.surfaceCard.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Holo.pink.withValues(alpha: 0.22)),
            boxShadow: Holo.floatingShadow,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                Holo.lilac.withValues(alpha: 0.12),
                Holo.cyan.withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HoloChip(
                child: Text(
                  revealed
                      ? context.tr('notebookStudyAnswer')
                      : context.tr('notebookStudyQuestion'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                word,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: notebookLanguage == 'ko' ? 'Pretendard' : null,
                  fontWeight: FontWeight.w900,
                  color: Holo.inkPlum,
                  height: 1.25,
                ),
              ),
              if (revealed) ...[
                if (reading != null && reading.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    reading,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Holo.pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: Holo.holoGradient,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  meaning.isEmpty
                      ? context.tr('notebookStudyNoMeaning')
                      : meaning,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Holo.inkPlum,
                    height: 1.4,
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    note,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Holo.inkPlumSoft),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: Holo.inkPlumSoft,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.tr('notebookStudyTapHint'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Holo.inkPlumSoft),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Holo.inkPlum,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Holo.inkPlumSoft),
          ),
        ],
      ),
    );
  }
}

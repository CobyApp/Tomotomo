import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
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
    return PaperScaffold(
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
    final p = context.paper;
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
              ).textTheme.labelLarge?.copyWith(color: p.inkSoft),
            ),
            const Spacer(),
            Text(
              '${_index + 1} / ${_cards.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PaperProgressBar(value: progress.clamp(0.0, 1.0), height: 14),
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
          PaperButton(
            icon: Icons.touch_app_rounded,
            label: context.tr('notebookStudyReveal'),
            onPressed: _reveal,
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _answer(known: false),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('notebookStudyAgain')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.ink,
                    side: BorderSide(color: p.cardEdge),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PaperRadii.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PaperButton(
                  icon: Icons.check_rounded,
                  label: context.tr('notebookStudyKnow'),
                  onPressed: () => _answer(known: true),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final p = context.paper;
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
                color: p.coral,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
                  BoxShadow(
                    color: p.softShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('notebookStudyComplete'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('notebookStudyScore', params: {'percent': '$percent'}),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: p.inkSoft),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ResultTile(
                    icon: Icons.refresh_rounded,
                    value: _review,
                    label: context.tr('notebookStudyAgain'),
                    color: p.coral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResultTile(
                    icon: Icons.check_rounded,
                    value: _known,
                    label: context.tr('notebookStudyKnow'),
                    color: p.stampBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PaperButton(
              icon: Icons.shuffle_rounded,
              label: context.tr('notebookStudyRestart'),
              onPressed: _restart,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('notebookStudyClose'),
                style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w700),
              ),
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

  (String?, String) get _translationParts => item.readingAndMeaning;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
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
            color: p.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: p.cardEdge),
            boxShadow: [
              BoxShadow(color: p.hardShadow, offset: const Offset(0, 4)),
              BoxShadow(
                color: p.softShadow,
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StampTicket(
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
                // The headword is content in notebookLanguage, so its font stack
                // follows that — not the app UI language, which is what the
                // theme's headlineMedium was keyed to. Saving 这个 from a Chinese
                // friend and studying it under a Korean UI drew 这 and 个 in two
                // different typefaces.
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamilyFallback: cuteDisplayFallback(notebookLanguage),
                  fontFamily: notebookLanguage == 'ko' ? 'Pretendard' : null,
                  fontWeight: FontWeight.w900,
                  color: p.ink,
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
                      color: p.coral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(
                    color: p.coral,
                    borderRadius: BorderRadius.circular(PaperRadii.pill),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  meaning.isEmpty
                      ? context.tr('notebookStudyNoMeaning')
                      : meaning,
                  textAlign: TextAlign.center,
                  // Body font, not the display font: meanings are full
                  // sentences and the chunky display face is hard to read.
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.ink,
                    height: 1.5,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
                    ).textTheme.bodyMedium?.copyWith(color: p.inkSoft),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 18, color: p.inkSoft),
                    const SizedBox(width: 7),
                    Text(
                      context.tr('notebookStudyTapHint'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: p.inkSoft),
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
    final p = context.paper;
    return PaperCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

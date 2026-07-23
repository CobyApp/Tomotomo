import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale/languages.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/character/characters_data.dart';
import '../../data/on_device/on_device_model_config.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../domain/entities/character_record.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'onboarding_notifier.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// First-run flow. The app language is taken automatically from the device
/// locale; the only question is which language to learn. An intro carousel
/// plays while the on-device model downloads in the background; the user
/// enters the app immediately and chat unlocks once the model is ready.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  String? _studyLanguage;
  bool _saving = false;

  static const _introCount = 3;
  int get _pageCount => _introCount + 1; // intro slides + language pick
  bool get _onLastPage => _page == _pageCount - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 1) App language follows the device locale (no question asked).
    try {
      final p = await context.read<ProfileRepository>().getProfile(_localUserId);
      if (p != null && mounted) {
        final devLang = normalizeLang(
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
        );
        await context.read<LocaleNotifier>().setAppLanguage(devLang, p);
      }
    } catch (_) {}
    // 2) Start the model download in the background while the user onboards.
    if (!mounted) return;
    final manager = context.read<OnDeviceModelManager>();
    if (!manager.isReady) unawaited(manager.install());
  }

  void _next() {
    if (_onLastPage) {
      unawaited(_finish());
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final lang = _studyLanguage;
    if (lang == null || _saving) return;
    setState(() => _saving = true);
    try {
      // Create exactly one friend, in the chosen study language.
      final repo = context.read<CharacterRecordRepository>();
      final match = characters.where((c) => c.friendLanguage == lang);
      if (match.isNotEmpty) {
        final c = match.first;
        final persona = [c.description.trim(), c.speechStyle.trim()]
            .where((s) => s.isNotEmpty)
            .join('\n');
        final now = DateTime.now();
        await repo.createCharacter(
          CharacterRecord(
            id: c.id,
            name: c.displayNamePrimary,
            avatarUrl: c.imagePath.isEmpty ? null : c.imagePath,
            tagline: c.tagline.isEmpty ? null : c.tagline,
            speechStyle: persona.isEmpty ? null : persona,
            language: c.friendLanguage,
            level: c.level,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      await context.read<OnboardingNotifier>().complete();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return PaperScaffold(
      title: 'トモトモ',
      useWordmark: true,
      transparentBackground: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _IntroSlide(
                    assetImage: 'assets/images/app_icon.png',
                    title: context.tr('onboardingIntro1Title'),
                    body: context.tr('onboardingIntro1Body'),
                  ),
                  _IntroSlide(
                    icon: Icons.menu_book_rounded,
                    title: context.tr('onboardingIntro2Title'),
                    body: context.tr('onboardingIntro2Body'),
                  ),
                  _IntroSlide(
                    icon: Icons.offline_bolt_rounded,
                    title: context.tr('onboardingIntro3Title'),
                    body: context.tr('onboardingIntro3Body'),
                  ),
                  _StudyLanguagePage(
                    selected: _studyLanguage,
                    onSelected: (code) => setState(() => _studyLanguage = code),
                  ),
                ],
              ),
            ),
            const _DownloadStatus(),
            _Dots(count: _pageCount, index: _page, color: p.coral, edge: p.cardEdge),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                12,
                AppSpacing.pageH,
                16,
              ),
              child: _saving
                  ? Center(child: PaperLoading(size: 9))
                  : PaperButton(
                      label: _onLastPage
                          ? context.tr('onboardingStart')
                          : context.tr('onboardingNext'),
                      icon: _onLastPage ? Icons.favorite_rounded : null,
                      onPressed: (_onLastPage && _studyLanguage == null)
                          ? null
                          : _next,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clear, always-visible model-download status card. Shows a friendly message
/// and a real percentage across every phase so the user knows the friend is on
/// the way — and offers retry on failure.
class _DownloadStatus extends StatelessWidget {
  const _DownloadStatus();

  static String _gb(double fraction) =>
      (OnDeviceModelConfig.byteCount * fraction.clamp(0.0, 1.0) / 1e9)
          .toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Consumer<OnDeviceModelManager>(
      builder: (context, manager, _) {
        final snap = manager.snapshot;
        final phase = snap.phase;
        if (phase == OnDeviceModelPhase.ready) {
          return _row(
            context,
            icon: Icons.check_circle_rounded,
            color: p.coral,
            text: context.tr('modelDlReady'),
          );
        }
        if (phase == OnDeviceModelPhase.error) {
          return _row(
            context,
            icon: Icons.error_outline_rounded,
            color: p.coralDeep,
            text: context.tr('modelDlError'),
            trailing: TextButton(
              onPressed: () => manager.install(),
              child: Text(context.tr('retry')),
            ),
          );
        }
        final downloading = phase == OnDeviceModelPhase.downloading;
        final pct = (snap.progress.clamp(0.0, 1.0) * 100).round();
        final title = downloading
            ? context.tr('modelDlProgress')
            : phase == OnDeviceModelPhase.finalizing
            ? context.tr('onDeviceModelFinalizing')
            : context.tr('modelDlStarting');
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 4, AppSpacing.pageH, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(PaperRadii.card),
              border: Border.all(color: p.cardEdge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 18, height: 18, child: PaperLoading(size: 6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (downloading)
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: p.coral,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(PaperRadii.pill),
                  child: LinearProgressIndicator(
                    value: downloading ? snap.progress.clamp(0.0, 1.0) : null,
                    minHeight: 6,
                    backgroundColor: p.cardEdge,
                    valueColor: AlwaysStoppedAnimation(p.coral),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  downloading
                      ? '${_gb(snap.progress)} / ${_gb(1)} GB · ${context.tr('modelDlHint')}'
                      : context.tr('modelDlHint'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    Widget? trailing,
  }) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 4, AppSpacing.pageH, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(PaperRadii.card),
          border: Border.all(color: p.cardEdge),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    this.icon,
    this.assetImage,
    required this.title,
    required this.body,
  });

  final IconData? icon;
  final String? assetImage;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetImage != null)
            Container(
              width: 104,
              height: 104,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: p.softShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(assetImage!, fit: BoxFit.cover),
            )
          else
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: p.coral.withValues(alpha: 0.20)),
              ),
              child: Icon(icon, size: 44, color: p.coral),
            ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: cuteDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _StudyLanguagePage extends StatelessWidget {
  const _StudyLanguagePage({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  static const _languages = ['ko', 'ja', 'en', 'zh'];

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.pageTop,
        AppSpacing.pageH,
        AppSpacing.pageBottom,
      ),
      children: [
        Text(
          context.tr('onboardingStudyTitle'),
          style: cuteDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('onboardingStudySubtitle'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.4),
        ),
        const SizedBox(height: 20),
        for (final code in _languages) ...[
          _LangCard(
            symbol: _stampSymbol(code),
            label: languageEndonym(code),
            selected: selected == code,
            onTap: () => onSelected(code),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  static String _stampSymbol(String code) => switch (code) {
    'ja' => 'あ',
    'en' => 'A',
    'zh' => '中',
    _ => '한',
  };
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.symbol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return InkWell(
      borderRadius: BorderRadius.circular(PaperRadii.card),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(PaperRadii.card),
          border: Border.all(
            color: selected ? p.coral : p.cardEdge,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
            BoxShadow(color: p.softShadow, blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.coral.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Text(
                symbol,
                style: cuteDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.coral,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: p.coral, size: 24),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.color,
    required this.edge,
  });

  final int count;
  final int index;
  final Color color;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? color : edge,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

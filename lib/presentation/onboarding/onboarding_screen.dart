import 'dart:async';
import '../../core/ui/paper/paper_loading.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/friend_language_notifier.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'onboarding_notifier.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// First-run setup: app language, nickname + nationality, friend language.
/// On finish it persists the profile and flips [OnboardingNotifier] so the
/// [App] gate rebuilds into the main shell.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 3;

  final _nicknameController = TextEditingController();

  Profile? _profile;
  int _step = 0;
  String? _nationality; // 'ko' | 'ja' | 'en' | 'zh' | 'other'
  String? _friendLanguage; // 'ko' | 'ja' | 'en' | 'zh'
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadProfile());
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = context.read<ProfileRepository>();
      final p = await repo.getProfile(_localUserId);
      if (!mounted || p == null) return;
      setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _selectAppLanguage(String code) async {
    final profile = _profile;
    if (profile == null) return;
    // Persist + apply live so the rest of onboarding renders in this language.
    await context.read<LocaleNotifier>().setAppLanguage(code, profile);
    if (!mounted) return;
    setState(() => _profile = profile.copyWith(appLanguage: code));
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _profile != null;
      case 1:
        return _nicknameController.text.trim().isNotEmpty &&
            _nationality != null;
      case 2:
        return _friendLanguage != null;
      default:
        return false;
    }
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() {
        _error = null;
        _step++;
      });
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _error = null;
        _step--;
      });
    }
  }

  Future<void> _finish() async {
    final profile = _profile;
    final friend = _friendLanguage;
    if (profile == null || friend == null) return;
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = context.trRead('onboardingNicknameRequired'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      await repo.updateProfile(
        profile.copyWith(displayName: nickname, learningLanguage: friend),
      );
      await repo.setNationality(_nationality);
      if (!mounted) return;
      await context.read<FriendLanguageNotifier>().setLanguage(friend);
      if (!mounted) return;
      // Flips the gate in [App]; the main shell mounts on the next rebuild.
      await context.read<OnboardingNotifier>().complete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final isLast = _step == _stepCount - 1;

    return PaperScaffold(
      title: 'トモトモ',
      useWordmark: true,
      transparentBackground: false,
      body: SafeArea(
        child: Column(
          children: [
            _StepProgress(step: _step, count: _stepCount),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageH,
                    AppSpacing.pageTop,
                    AppSpacing.pageH,
                    AppSpacing.pageBottom,
                  ),
                  child: _buildStep(context),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageH,
                  0,
                  AppSpacing.pageH,
                  8,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: p.coralDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                4,
                AppSpacing.pageH,
                16,
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    TextButton(
                      onPressed: _saving ? null : _back,
                      style: TextButton.styleFrom(foregroundColor: p.inkSoft),
                      child: Text(
                        context.tr('onboardingBack'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _saving
                        ? Center(
                            child: PaperLoading(size: 9),
                          )
                        : PaperButton(
                            label: isLast
                                ? context.tr('onboardingStart')
                                : context.tr('onboardingNext'),
                            icon: isLast ? Icons.favorite_rounded : null,
                            onPressed: _canAdvance
                                ? (isLast ? _finish : _next)
                                : null,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _stepAppLanguage(context);
      case 1:
        return _stepProfile(context);
      default:
        return _stepFriendLanguage(context);
    }
  }

  // ── Step 1: app language ──────────────────────────────────────
  Widget _stepAppLanguage(BuildContext context) {
    final appLang = _profile?.appLanguage;
    final p = context.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            margin: const EdgeInsets.only(top: 4, bottom: 18),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: p.softShadow,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        _StepHeading(
          title: context.tr('onboardingStep1Title'),
          subtitle: context.tr('onboardingStep1Subtitle'),
        ),
        const SizedBox(height: 20),
        _ChoiceCard(
          leading: _LangStamp('한'),
          label: '한국어',
          selected: appLang == 'ko',
          onTap: () => _selectAppLanguage('ko'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('あ'),
          label: '日本語',
          selected: appLang == 'ja',
          onTap: () => _selectAppLanguage('ja'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('A'),
          label: 'English',
          selected: appLang == 'en',
          onTap: () => _selectAppLanguage('en'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('中'),
          label: '中文',
          selected: appLang == 'zh',
          onTap: () => _selectAppLanguage('zh'),
        ),
      ],
    );
  }

  // ── Step 2: nickname + nationality ────────────────────────────
  Widget _stepProfile(BuildContext context) {
    final p = context.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: context.tr('onboardingStep2Title'),
          subtitle: context.tr('onboardingStep2Subtitle'),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nicknameController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: context.tr('onboardingNicknameHint'),
            filled: true,
            fillColor: p.card,
            hintStyle: TextStyle(color: p.inkSoft),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PaperRadii.button),
              borderSide: BorderSide(color: p.cardEdge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PaperRadii.button),
              borderSide: BorderSide(color: p.cardEdge),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PaperRadii.button),
              borderSide: BorderSide(color: p.coral, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('onboardingNationalityLabel'),
          style: cuteDisplay(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          leading: _LangStamp('한'),
          label: context.tr('onboardingNationalityKo'),
          selected: _nationality == 'ko',
          compact: true,
          onTap: () => setState(() => _nationality = 'ko'),
        ),
        const SizedBox(height: 10),
        _ChoiceCard(
          leading: _LangStamp('あ'),
          label: context.tr('onboardingNationalityJa'),
          selected: _nationality == 'ja',
          compact: true,
          onTap: () => setState(() => _nationality = 'ja'),
        ),
        const SizedBox(height: 10),
        _ChoiceCard(
          leading: _LangStamp('A'),
          label: context.tr('onboardingNationalityEn'),
          selected: _nationality == 'en',
          compact: true,
          onTap: () => setState(() => _nationality = 'en'),
        ),
        const SizedBox(height: 10),
        _ChoiceCard(
          leading: _LangStamp('中'),
          label: context.tr('onboardingNationalityZh'),
          selected: _nationality == 'zh',
          compact: true,
          onTap: () => setState(() => _nationality = 'zh'),
        ),
        const SizedBox(height: 10),
        _ChoiceCard(
          leading: _LangStamp('', icon: Icons.public_rounded),
          label: context.tr('onboardingNationalityOther'),
          selected: _nationality == 'other',
          compact: true,
          onTap: () => setState(() => _nationality = 'other'),
        ),
      ],
    );
  }

  // ── Step 3: friend language ───────────────────────────────────
  Widget _stepFriendLanguage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: context.tr('onboardingStep3Title'),
          subtitle: context.tr('onboardingStep3Subtitle'),
        ),
        const SizedBox(height: 20),
        _ChoiceCard(
          leading: _LangStamp('あ'),
          label: context.tr('onboardingFriendJa'),
          selected: _friendLanguage == 'ja',
          onTap: () => setState(() => _friendLanguage = 'ja'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('한'),
          label: context.tr('onboardingFriendKo'),
          selected: _friendLanguage == 'ko',
          onTap: () => setState(() => _friendLanguage = 'ko'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('A'),
          label: context.tr('onboardingFriendEn'),
          selected: _friendLanguage == 'en',
          onTap: () => setState(() => _friendLanguage = 'en'),
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          leading: _LangStamp('中'),
          label: context.tr('onboardingFriendZh'),
          selected: _friendLanguage == 'zh',
          onTap: () => setState(() => _friendLanguage = 'zh'),
        ),
      ],
    );
  }
}

/// Slim three-segment progress bar across the top of the flow.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.count});
  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        8,
        AppSpacing.pageH,
        4,
      ),
      child: Row(
        children: List.generate(count, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
              height: 6,
              decoration: BoxDecoration(
                color: active ? p.coral : p.cardEdge,
                borderRadius: BorderRadius.circular(PaperRadii.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Big friendly step title + supporting line.
class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: cuteDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 15, height: 1.4, color: p.inkSoft),
        ),
      ],
    );
  }
}

/// Tappable paper choice card with a coral selected state.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return InkWell(
      borderRadius: BorderRadius.circular(PaperRadii.card),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: compact ? 16 : 22,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(PaperRadii.card),
          border: Border.all(
            color: selected ? p.coral : p.cardEdge,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
            BoxShadow(
              color: p.softShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
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

/// Paper "stamp" badge used on onboarding choice cards instead of glossy flag
/// emojis — each language shows its own script character (한 / あ / A / 中),
/// keeping the leading mark consistent with the paper-cartoon theme.
class _LangStamp extends StatelessWidget {
  const _LangStamp(this.symbol, {this.icon});

  final String symbol;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.coral.withValues(alpha: 0.5), width: 1.5),
      ),
      child: icon != null
          ? Icon(icon, color: p.coral, size: 22)
          : Text(
              symbol,
              style: cuteDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.coral,
              ),
            ),
    );
  }
}

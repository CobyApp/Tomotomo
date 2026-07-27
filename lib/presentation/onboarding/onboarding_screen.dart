import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/image/image_crop.dart';
import '../../core/locale/languages.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/character/characters_data.dart';
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

  // First-friend form (pre-filled from the built-in example for the chosen
  // study language; fully editable before the user finishes onboarding).
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _personaController = TextEditingController();
  // The learner's own name — saved to their profile so friends address them by
  // name from the very first message.
  final _myNameController = TextEditingController();
  String _level = 'beginner';
  String? _avatarPath;
  String? _prefillLang;
  bool _pickingAvatar = false;
  // The learner's own profile photo picked on the profile page.
  String? _myAvatarPath;
  bool _pickingMyAvatar = false;

  static const _introCount = 3;
  // intro slides + profile (your name) + language pick + first-friend page.
  int get _profilePageIndex => _introCount;
  int get _pageCount => _introCount + 3;
  bool get _onLastPage => _page == _pageCount - 1;

  /// Gate the profile page (needs your name) and the final friend page (needs
  /// the friend's name). A study language is always pre-selected.
  bool get _nextBlocked {
    if (_page == _profilePageIndex) {
      return _myNameController.text.trim().isEmpty;
    }
    if (_onLastPage) return _nameController.text.trim().isEmpty;
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Pre-select the study language from the device locale so the language
    // page opens with a choice already highlighted and paging never dead-ends.
    _studyLanguage = normalizeLang(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    // Re-evaluate the Next/Start button as the name fields are edited.
    void rebuild() {
      if (mounted) setState(() {});
    }

    _nameController.addListener(rebuild);
    _myNameController.addListener(rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _personaController.dispose();
    _myNameController.dispose();
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
        // Pre-fill the learner's name if a profile already has one.
        final existingName = p.displayName?.trim() ?? '';
        if (existingName.isNotEmpty && _myNameController.text.isEmpty) {
          _myNameController.text = existingName;
        }
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

  /// Pre-fills the first-friend form with the packaged example that matches the
  /// chosen study language. Runs when the user lands on the friend page (and
  /// again if they go back and switch languages).
  ///
  /// The bio/personality text follows the APP UI language (an English-UI user
  /// must be able to read the prefill); only the speech-style example phrases
  /// stay in the friend's language — they are persona data, not explanation.
  void _prefillFirstFriend() {
    final lang = _studyLanguage;
    if (lang == null || _prefillLang == lang) return;
    final match = characters.where((c) => c.friendLanguage == lang);
    if (match.isEmpty) return;
    final c = match.first;
    _nameController.text = c.displayNamePrimary;
    _taglineController.text = context.trRead('tplTagline_$lang');
    _personaController.text = [
      context.trRead('tplPersona_$lang'),
      c.speechStyle.trim(),
    ].where((s) => s.isNotEmpty).join('\n');
    setState(() {
      _level = c.level;
      _prefillLang = lang;
    });
  }

  /// Gallery pick → square crop → copy into the app's avatars dir.
  /// Returns the stored path, or null when cancelled/failed.
  Future<String?> _pickAndStoreAvatar() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (x == null || !mounted) return null;
    final cropped = await cropImagePath(x.path, square: true);
    if (cropped == null || !mounted) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${dir.path}/avatars');
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }
      final ext = cropped.contains('.') ? cropped.split('.').last : 'jpg';
      final dest =
          '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(cropped).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFirstFriendAvatar() async {
    setState(() => _pickingAvatar = true);
    final dest = await _pickAndStoreAvatar();
    if (!mounted) return;
    setState(() {
      if (dest != null) _avatarPath = dest;
      _pickingAvatar = false;
    });
  }

  Future<void> _pickMyAvatar() async {
    setState(() => _pickingMyAvatar = true);
    final dest = await _pickAndStoreAvatar();
    if (!mounted) return;
    setState(() {
      if (dest != null) _myAvatarPath = dest;
      _pickingMyAvatar = false;
    });
  }

  Future<void> _finish() async {
    final lang = _studyLanguage;
    final name = _nameController.text.trim();
    if (lang == null || name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      // Create the user's own first friend from the (pre-filled, editable)
      // form — no built-in seeding, no points cost on first run.
      final repo = context.read<CharacterRecordRepository>();
      final profileRepo = context.read<ProfileRepository>();
      final tagline = _taglineController.text.trim();
      final persona = _personaController.text.trim();
      await repo.createCharacter(
        CharacterRecord.draft(
          name: name,
          avatarUrl: _avatarPath,
          tagline: tagline.isEmpty ? null : tagline,
          speechStyle: persona.isEmpty ? null : persona,
          language: lang,
          level: _level,
        ),
      );
      // Save the learner's own name to their profile so friends greet them by
      // name from the first message.
      final myName = _myNameController.text.trim();
      if (myName.isNotEmpty || _myAvatarPath != null) {
        try {
          // getProfile creates+persists a default profile when absent.
          final existing = await profileRepo.getProfile(_localUserId);
          if (existing != null) {
            await profileRepo.updateProfile(
              existing.copyWith(
                displayName: myName.isEmpty ? null : myName,
                avatarUrl: _myAvatarPath,
              ),
            );
          }
        } catch (_) {}
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
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _page = i);
                  if (i == _pageCount - 1) _prefillFirstFriend();
                },
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
                  _ProfilePage(
                    myNameController: _myNameController,
                    avatarPath: _myAvatarPath,
                    picking: _pickingMyAvatar,
                    onPickAvatar: _pickMyAvatar,
                  ),
                  _StudyLanguagePage(
                    selected: _studyLanguage,
                    onSelected: (code) => setState(() => _studyLanguage = code),
                  ),
                  _FirstFriendPage(
                    nameController: _nameController,
                    taglineController: _taglineController,
                    personaController: _personaController,
                    level: _level,
                    onLevel: (v) => setState(() => _level = v),
                    avatarPath: _avatarPath,
                    pickingAvatar: _pickingAvatar,
                    onPickAvatar: _pickFirstFriendAvatar,
                    onClearAvatar: () => setState(() => _avatarPath = null),
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
                      onPressed: _nextBlocked ? null : _next,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin floating model-download pill — the same compact style as the
/// main-screen [ModelDownloadBanner], shown above the onboarding button so the
/// download stays unobtrusive while the user sets up their friend.
class _DownloadStatus extends StatelessWidget {
  const _DownloadStatus();

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Consumer<OnDeviceModelManager>(
      builder: (context, manager, _) {
        final snap = manager.snapshot;
        final phase = snap.phase;
        final pct = (snap.progress.clamp(0.0, 1.0) * 100).round();

        final Widget lead;
        final String title;
        Widget? trailing;
        if (phase == OnDeviceModelPhase.ready) {
          lead = Icon(Icons.check_circle_rounded, size: 16, color: p.coral);
          title = context.tr('modelDlReady');
        } else if (phase == OnDeviceModelPhase.error) {
          lead = Icon(Icons.error_outline_rounded, size: 16, color: p.coralDeep);
          title = context.tr('modelDlError');
          trailing = TextButton(
            onPressed: () => manager.install(),
            style: TextButton.styleFrom(
              foregroundColor: p.coralDeep,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(context.tr('retry')),
          );
        } else {
          lead = PaperLoading(size: 5);
          if (phase == OnDeviceModelPhase.downloading) {
            title = context.tr('modelDlProgress');
            trailing = Text(
              '$pct%',
              style: TextStyle(
                color: p.coral,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            );
          } else if (phase == OnDeviceModelPhase.finalizing) {
            title = context.tr('onDeviceModelFinalizing');
          } else {
            title = context.tr('modelDlStarting');
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 2, AppSpacing.pageH, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.ink, width: 2.5),
              boxShadow: [
                BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                lead,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        );
      },
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.ink, width: 2.5),
                // DecorationImage clips the image cleanly inside the border —
                // no corner bleed like a clipped child image has.
                image: DecorationImage(
                  image: AssetImage(assetImage!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
                ],
              ),
            )
          else
            // Same pastel-sticker look as slide 1's app icon: soft pink→blue
            // gradient tile, ink border, hard offset shadow, gloss, and a
            // coral-gradient glyph — so the three slides read as one set.
            Container(
              width: 104,
              height: 104,
              foregroundDecoration: stickerGloss(
                borderRadius: BorderRadius.circular(28),
                strength: 0.22,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE0F4), Color(0xFFD8ECFF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.ink, width: 2.5),
                boxShadow: [
                  BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.coral, p.coralDeep],
                ).createShader(rect),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
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
    // Opaque light-pink tint when selected (pre-blended so it never composites
    // dark over the Material below), plus a coral border for a clear state.
    final selectedFill = Color.alphaBlend(
      p.coral.withValues(alpha: 0.16),
      p.card,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? selectedFill : p.card,
          borderRadius: BorderRadius.circular(PaperRadii.card),
          border: Border.all(
            color: selected ? p.coral : p.ink,
            width: selected ? 3 : 2.5,
          ),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.ink, width: 2),
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

/// Profile step: the learner's own name (saved to their profile so friends
/// greet them by name). Kept separate from the friend-creation step.
class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.myNameController,
    required this.avatarPath,
    required this.picking,
    required this.onPickAvatar,
  });

  final TextEditingController myNameController;
  final String? avatarPath;
  final bool picking;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final radius = BorderRadius.circular(PaperRadii.button);
    final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.pageTop,
        AppSpacing.pageH,
        AppSpacing.pageBottom,
      ),
      children: [
        Text(
          context.tr('onboardingProfileTitle'),
          style: cuteDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('onboardingProfileSubtitle'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.4),
        ),
        const SizedBox(height: 28),
        // Same tappable photo circle + camera badge as the friend page, so
        // the learner can set their own picture right away (optional).
        Center(
          child: GestureDetector(
            onTap: picking ? null : onPickAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasAvatar ? null : p.paperBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.ink, width: 2.5),
                    image: hasAvatar
                        ? DecorationImage(
                            image: FileImage(File(avatarPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: p.hardShadow,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: picking
                      ? const Center(child: PaperLoading(size: 8))
                      : hasAvatar
                      ? null
                      : Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: p.inkSoft.withValues(alpha: 0.75),
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.coral,
                      border: Border.all(color: p.card, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            context.tr('onboardingYourName'),
            style: cuteDisplay(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: p.coral,
            ),
          ),
        ),
        TextField(
          controller: myNameController,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: p.ink, fontSize: 15),
          decoration: InputDecoration(
            hintText: context.tr('onboardingYourNameHint'),
            hintStyle: TextStyle(color: p.inkSoft.withValues(alpha: 0.7)),
            filled: true,
            fillColor: p.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: p.ink, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: p.ink, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: p.coral, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// The final onboarding step: the user's own first friend, pre-filled with a
/// packaged example for the chosen study language and fully editable.
class _FirstFriendPage extends StatelessWidget {
  const _FirstFriendPage({
    required this.nameController,
    required this.taglineController,
    required this.personaController,
    required this.level,
    required this.onLevel,
    required this.avatarPath,
    required this.pickingAvatar,
    required this.onPickAvatar,
    required this.onClearAvatar,
  });

  final TextEditingController nameController;
  final TextEditingController taglineController;
  final TextEditingController personaController;
  final String level;
  final ValueChanged<String> onLevel;
  final String? avatarPath;
  final bool pickingAvatar;
  final VoidCallback onPickAvatar;
  final VoidCallback onClearAvatar;

  static const _levels = [
    ('beginner', 'levelBeginner'),
    ('intermediate', 'levelIntermediate'),
    ('advanced', 'levelAdvanced'),
    ('business', 'levelBusiness'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.pageTop,
        AppSpacing.pageH,
        AppSpacing.pageBottom,
      ),
      children: [
        Text(
          context.tr('onboardingFriendTitle'),
          style: cuteDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('onboardingFriendSubtitle'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.4),
        ),
        const SizedBox(height: 20),
        // Avatar: plain-person default; tap to add a photo.
        Center(
          child: GestureDetector(
            onTap: pickingAvatar ? null : onPickAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasAvatar ? null : p.paperBg,
                    border: Border.all(color: p.ink, width: 2.5),
                    image: hasAvatar
                        ? DecorationImage(
                            image: FileImage(File(avatarPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
                    ],
                  ),
                  child: pickingAvatar
                      ? const Center(child: PaperLoading(size: 8))
                      : hasAvatar
                      ? null
                      : Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: p.inkSoft.withValues(alpha: 0.75),
                          ),
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.coral,
                      border: Border.all(color: p.card, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasAvatar)
          Center(
            child: TextButton(
              onPressed: onClearAvatar,
              child: Text(context.tr('characterRemoveAvatar')),
            ),
          )
        else
          const SizedBox(height: 18),
        _label(context, context.tr('name')),
        _field(context, controller: nameController),
        const SizedBox(height: 16),
        _label(context, context.tr('characterTaglineLabel')),
        _field(
          context,
          controller: taglineController,
          hint: context.tr('characterTaglineHint'),
        ),
        const SizedBox(height: 16),
        _label(context, context.tr('characterMemo')),
        _field(
          context,
          controller: personaController,
          hint: context.tr('characterMemoHint'),
          maxLines: 4,
          minLines: 3,
        ),
        const SizedBox(height: 20),
        _label(context, context.tr('levelSectionTitle')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, key) in _levels)
              PaperChip(
                label: context.tr(key),
                selected: level == value,
                onTap: () => onLevel(value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Text(
        text,
        style: cuteDisplay(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: context.paper.coral,
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    String? hint,
    int? maxLines = 1,
    int? minLines,
  }) {
    final p = context.paper;
    final radius = BorderRadius.circular(PaperRadii.button);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(color: p.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.inkSoft.withValues(alpha: 0.7)),
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.ink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.coral, width: 2.5),
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

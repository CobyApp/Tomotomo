import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/locale/l10n_context.dart';
import '../ui/paper/paper_scaffold.dart';
import '../ui/paper/paper_theme.dart';
import '../ui/paper/paper_tokens.dart';
import '../ui/paper/paper_widgets.dart';
import 'update_config.dart';

/// Where the remote gate config lives (GitHub Pages serves from the repo root,
/// so the docs are under `/docs`).
final Uri _versionConfigUrl = Uri.parse(
  'https://cobyapp.github.io/Tomotomo/docs/version.json',
);

/// Wraps the whole app. On launch it does a best-effort check of the remote
/// version gate. Forced → replaces everything with a non-dismissible update
/// screen. Recommended → overlays a dismissible banner. Offline / any failure
/// → passes straight through (never blocks offline use).
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  UpdateStatus _status = UpdateStatus.ok;
  RemoteVersionConfig? _config;
  bool _recommendedDismissed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final config = await fetchVersionConfig(_versionConfigUrl);
      if (config == null || !mounted) return;
      final status = evaluateUpdate(currentBuild: current, config: config);
      if (status == UpdateStatus.ok) return;
      setState(() {
        _config = config;
        _status = status;
      });
    } catch (_) {
      // Offline or any failure — do not block.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == UpdateStatus.forced) {
      return _ForceUpdateScreen(storeUrl: _config?.storeUrl);
    }
    return Stack(
      children: [
        widget.child,
        if (_status == UpdateStatus.recommended && !_recommendedDismissed)
          _RecommendUpdateBanner(
            storeUrl: _config?.storeUrl,
            onDismiss: () => setState(() => _recommendedDismissed = true),
          ),
      ],
    );
  }
}

Future<void> _openStore(String? storeUrl) async {
  if (storeUrl == null || storeUrl.trim().isEmpty) return;
  final uri = Uri.tryParse(storeUrl.trim());
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Non-dismissible full-screen gate shown when the build is below `min_build`.
class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({this.storeUrl});

  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final hasStore = storeUrl != null && storeUrl!.trim().isNotEmpty;
    return PopScope(
      canPop: false,
      child: PaperScaffold(
        title: context.tr('updateForcedTitle'),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🚀', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 18),
                Text(
                  context.tr('updateForcedTitle'),
                  textAlign: TextAlign.center,
                  style: cuteDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('updateForcedBody'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: p.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                if (hasStore)
                  PaperButton(
                    label: context.tr('updateNowButton'),
                    onPressed: () => _openStore(storeUrl),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dismissible top banner shown when a newer (non-mandatory) build exists.
class _RecommendUpdateBanner extends StatelessWidget {
  const _RecommendUpdateBanner({
    required this.onDismiss,
    this.storeUrl,
  });

  final VoidCallback onDismiss;
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final hasStore = storeUrl != null && storeUrl!.trim().isNotEmpty;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.ink, width: 2.5),
                boxShadow: [
                  BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('updateRecommendedTitle'),
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (hasStore)
                    TextButton(
                      onPressed: () => _openStore(storeUrl),
                      child: Text(
                        context.tr('updateNowShort'),
                        style: TextStyle(
                          color: p.coralDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: p.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

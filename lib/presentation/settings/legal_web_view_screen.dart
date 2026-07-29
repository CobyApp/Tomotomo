import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

/// The legal / policy documents hosted on GitHub Pages.
enum LegalDoc { privacy, terms, marketing }

/// Base URL of the published legal site (GitHub Pages for CobyApp/Tomotomo).
/// Pages serves from the repo root, so the docs live under `/docs`.
const String _legalBaseUrl = 'https://cobyapp.github.io/Tomotomo/docs';

String _legalDocFile(LegalDoc doc) {
  switch (doc) {
    case LegalDoc.privacy:
      return 'privacy.html';
    case LegalDoc.terms:
      return 'terms.html';
    case LegalDoc.marketing:
      return 'marketing.html';
  }
}

/// Full-screen WebView that shows a legal document in the app's current
/// language (the page reads the `?lang=` query param).
class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({
    super.key,
    required this.doc,
    required this.title,
  });

  final LegalDoc doc;
  final String title;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  WebViewController? _controller;
  late final Uri _url;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final lang = context.read<LocaleNotifier>().languageCode;
    _url = Uri.parse('$_legalBaseUrl/${_legalDocFile(widget.doc)}?lang=$lang');
    // Guard controller creation: if the platform WebView is unavailable we
    // still show the screen with a "open in browser" fallback instead of a
    // failed navigation.
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            // Keep the in-app browser on our own documents. Without this the
            // legal page — served from a public Pages site — could navigate this
            // WebView anywhere, which is an in-app phishing surface if that site
            // is ever tampered with. Anything else opens in the real browser,
            // where the user can see the address bar.
            onNavigationRequest: (request) {
              final target = Uri.tryParse(request.url);
              if (target != null &&
                  target.scheme == 'https' &&
                  target.host.toLowerCase() == _url.host.toLowerCase()) {
                return NavigationDecision.navigate;
              }
              if (target != null && target.scheme == 'https') {
                unawaited(
                  launchUrl(target, mode: LaunchMode.externalApplication),
                );
              }
              return NavigationDecision.prevent;
            },
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (error) {
              // Only fail on the main document, not sub-resources.
              if ((error.isForMainFrame ?? true) && mounted) {
                setState(() {
                  _loading = false;
                  _error = true;
                });
              }
            },
          ),
        )
        ..loadRequest(_url);
    } catch (_) {
      _loading = false;
      _error = true;
    }
  }

  void _reload() {
    final controller = _controller;
    if (controller == null) {
      _openExternally();
      return;
    }
    setState(() {
      _error = false;
      _loading = true;
    });
    controller.loadRequest(_url);
  }

  Future<void> _openExternally() async {
    await launchUrl(_url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: widget.title,
      // This screen is pushed on its own (not inside the shell's
      // PaperBackground): without the background the transparent app bar had
      // nothing painted behind it and rendered black. Paint both the header
      // background and an opaque body so the WebView never flashes black.
      transparentBackground: false,
      body: Stack(
        children: [
          if (!_error && _controller != null)
            WebViewWidget(controller: _controller!),
          if (_loading && !_error)
            Center(child: PaperLoading(size: 10)),
          if (_error) _ErrorView(onRetry: _reload, onOpen: _openExternally),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.onOpen});

  final VoidCallback onRetry;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: p.inkSoft),
            const SizedBox(height: 14),
            Text(
              context.tr('legalLoadFailed'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: p.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            PaperButton(
              label: context.tr('legalRetry'),
              onPressed: onRetry,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => onOpen(),
              child: Text(
                context.tr('legalOpenInBrowser'),
                style: TextStyle(color: p.coralDeep, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

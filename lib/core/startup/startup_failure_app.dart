import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../locale/languages.dart';

/// Shown instead of the app when startup itself failed.
///
/// `main` used to let an initialization failure propagate, so `runApp` was never
/// reached: opening a corrupted box, or hitting a full disk, produced a blank
/// screen that died with no explanation. The only recovery a user could think of
/// is deleting the app — which takes the 2.6 GB model and every saved
/// conversation with it.
///
/// It cannot rely on the app's providers (the boxes they need are exactly what
/// failed), so it resolves its own strings from the device locale.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.onRetry, this.detail});

  /// Which step failed, shown only in debug builds. Users must never be given
  /// internals, but without this a startup failure is opaque to whoever has to
  /// fix it — there is no running app left to log from.

  /// Re-runs initialization. Corruption will not fix itself, but a transient
  /// cause (storage pressure, a locked file) can clear.
  final VoidCallback onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final lang = normalizeLang(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    String tr(String key) => AppStrings.of(lang, key);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      home: Scaffold(
        backgroundColor: const Color(0xFFFFFBF2),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🩹', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 18),
                Text(
                  tr('startupFailedTitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2038),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('startupFailedBody'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF6B6478),
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(tr('startupRetry')),
                ),
                if (kDebugMode && detail != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A93A6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

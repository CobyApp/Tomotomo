import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import '../locale/l10n_context.dart';
import 'model_download_labels.dart';
import 'on_device_model_setup_screen.dart';

/// Compact, tappable model-download progress pill shown app-wide (e.g. above the
/// bottom nav) so download progress is visible from the main screen, not only
/// inside chat/settings. Collapses to nothing once the model is ready.
class ModelDownloadBanner extends StatelessWidget {
  const ModelDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Consumer<OnDeviceModelManager>(
      builder: (context, manager, _) {
        final phase = manager.snapshot.phase;
        final failed = phase == OnDeviceModelPhase.error;
        final active =
            phase == OnDeviceModelPhase.downloading ||
            phase == OnDeviceModelPhase.finalizing;
        // Stay visible on failure — silently disappearing left the user with
        // no idea what happened and no way to start the download again.
        if (!active && !failed) return const SizedBox.shrink();

        final downloading = phase == OnDeviceModelPhase.downloading;
        final pct = (manager.snapshot.progress.clamp(0.0, 1.0) * 100).round();
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.navDockInset, 0, AppSpacing.navDockInset, 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const OnDeviceModelSetupScreen(),
                ),
              ),
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
                    if (failed)
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: p.coralDeep,
                      )
                    else
                      PaperLoading(size: 5),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            failed
                                ? context.tr('modelDlFailedShort')
                                : downloading
                                ? context.tr('modelDlProgress')
                                : context.tr('onDeviceModelFinalizing'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          // Concrete megabytes, so a long download never looks
                          // frozen behind a stationary percentage.
                          if (downloading)
                            Text(
                              modelDownloadSizeLabel(manager.snapshot.progress),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.inkSoft,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (failed)
                      // Full reset + fresh download, so a stuck/failed attempt
                      // can always be recovered from right here.
                      TextButton(
                        onPressed: () => manager.retryInstall(),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.tr('retry'),
                          style: TextStyle(
                            color: p.coralDeep,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Text(
                        downloading ? '$pct%' : '…',
                        style: TextStyle(
                          color: p.coral,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

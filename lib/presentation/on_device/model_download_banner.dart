import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_loading.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import '../locale/l10n_context.dart';
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
        final active =
            phase == OnDeviceModelPhase.downloading ||
            phase == OnDeviceModelPhase.finalizing;
        if (!active) return const SizedBox.shrink();

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
                    PaperLoading(size: 5),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('modelDlProgress'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader, TaskNotification, PermissionType;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_dialog.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/on_device/on_device_model_config.dart';
import '../../data/on_device/on_device_model_manager.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import '../locale/l10n_context.dart';

class OnDeviceModelSetupScreen extends StatelessWidget {
  const OnDeviceModelSetupScreen({super.key, this.requiredSetup = false});

  final bool requiredSetup;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<OnDeviceModelManager>();
    final snapshot = manager.snapshot;
    final p = context.paper;
    return PaperScaffold(
      title: context.tr('onDeviceModelTitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.coral.withValues(alpha: 0.20)),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 40, color: p.coral),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('onDeviceModelHeadline'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('onDeviceModelDescription'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.55),
          ),
          const SizedBox(height: 28),
          _ModelStatus(snapshot: snapshot),
          const SizedBox(height: 16),
          if (snapshot.phase == OnDeviceModelPhase.notInstalled ||
              snapshot.phase == OnDeviceModelPhase.error)
            PaperButton(
              icon: Icons.download_rounded,
              label: context.tr('onDeviceModelDownload'),
              onPressed: () => _startInstall(context, manager),
            ),
          if (snapshot.phase == OnDeviceModelPhase.downloading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: manager.cancelInstall,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.cardEdge),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PaperRadii.button),
                  ),
                ),
                child: Text(context.tr('cancel')),
              ),
            ),
          if (snapshot.phase == OnDeviceModelPhase.ready && !requiredSetup)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, manager),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(context.tr('onDeviceModelDelete')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.cardEdge),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PaperRadii.button),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.storage_rounded, size: 20, color: p.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    OnDeviceModelConfig.version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(OnDeviceModelConfig.byteCount / 1000000000).toStringAsFixed(2)} GB',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: p.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Configures a system notification (with a live progress bar on Android) for
  /// the flutter_gemma download group so progress is visible even when the app
  /// is backgrounded/closed, then starts the install.
  Future<void> _startInstall(
    BuildContext context,
    OnDeviceModelManager manager,
  ) async {
    // Read localized notification text before any await (no context across gaps).
    final running = TaskNotification(
      context.trRead('modelNotifRunningTitle'),
      context.trRead('modelNotifRunningBody'),
    );
    final complete = TaskNotification(
      context.trRead('modelNotifCompleteTitle'),
      context.trRead('modelNotifCompleteBody'),
    );
    final error = TaskNotification(
      context.trRead('modelNotifErrorTitle'),
      context.trRead('modelNotifErrorBody'),
    );
    try {
      await FileDownloader().permissions.request(PermissionType.notifications);
      // 'smart_downloads' is the group used by flutter_gemma's SmartDownloader.
      FileDownloader().configureNotificationForGroup(
        'smart_downloads',
        running: running,
        complete: complete,
        error: error,
        progressBar: true,
      );
    } catch (_) {
      // Notifications are best-effort; the download still proceeds without them.
    }
    await manager.install();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OnDeviceModelManager manager,
  ) async {
    final confirmed = await showPaperConfirm(
      context,
      title: context.tr('onDeviceModelDelete'),
      message: context.tr('onDeviceModelDeleteConfirm'),
      confirmLabel: context.tr('confirm'),
      destructive: true,
    );
    if (confirmed) await manager.deleteModel();
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.snapshot});

  final OnDeviceModelSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.paper;
    if (snapshot.phase == OnDeviceModelPhase.checking) {
      return _StatusCard(
        icon: Icons.search_rounded,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: p.coral),
          ),
        ),
      );
    }
    if (snapshot.phase == OnDeviceModelPhase.downloading) {
      final percent = (snapshot.progress * 100).round();
      return _StatusCard(
        icon: Icons.downloading_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('onDeviceModelDownload'),
                    style: TextStyle(color: p.ink),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(PaperRadii.pill),
              child: LinearProgressIndicator(
                value: snapshot.progress,
                minHeight: 8,
                backgroundColor: p.cardEdge,
                valueColor: AlwaysStoppedAnimation(p.coral),
              ),
            ),
          ],
        ),
      );
    }
    if (snapshot.phase == OnDeviceModelPhase.ready) {
      return _StatusCard(
        icon: Icons.check_rounded,
        iconColor: p.stampBlue,
        iconBackground: p.stampBlue.withValues(alpha: 0.14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('onDeviceModelReady'),
              style: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
            ),
            if (snapshot.backend != null) ...[
              const SizedBox(height: 3),
              Text(
                'Backend · ${snapshot.backend}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
              ),
            ],
          ],
        ),
      );
    }
    if (snapshot.phase == OnDeviceModelPhase.error) {
      return _StatusCard(
        icon: Icons.error_outline_rounded,
        iconColor: scheme.error,
        iconBackground: scheme.errorContainer,
        child: Text(
          snapshot.errorMessage ?? context.tr('onDeviceModelError'),
          style: TextStyle(color: scheme.error, height: 1.4),
        ),
      );
    }
    return _StatusCard(
      icon: Icons.smart_toy_outlined,
      child: Text(
        context.tr('onDeviceModelNotInstalled'),
        style: TextStyle(color: p.ink, height: 1.4),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.child,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final Widget child;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return PaperCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground ?? p.coral.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor ?? p.coral, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

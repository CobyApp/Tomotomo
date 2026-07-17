import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/ui.dart';
import '../../core/ui/holo/holo_tokens.dart';
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
    return AppPageScaffold(
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
                color: Holo.pink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Holo.pink.withValues(alpha: 0.14)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: Holo.pink,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('onDeviceModelHeadline'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('onDeviceModelDescription'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Holo.inkPlumSoft,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          _ModelStatus(snapshot: snapshot),
          const SizedBox(height: 16),
          if (snapshot.phase == OnDeviceModelPhase.notInstalled ||
              snapshot.phase == OnDeviceModelPhase.error)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: manager.install,
                icon: const Icon(Icons.download_rounded),
                label: Text(context.tr('onDeviceModelDownload')),
              ),
            ),
          if (snapshot.phase == OnDeviceModelPhase.downloading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: manager.cancelInstall,
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
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Holo.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadii.cardSmall),
              border: Border.all(color: Holo.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storage_rounded,
                  size: 20,
                  color: Holo.inkPlumSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    OnDeviceModelConfig.version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Holo.inkPlumSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(OnDeviceModelConfig.byteCount / 1000000000).toStringAsFixed(2)} GB',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Holo.inkPlum),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OnDeviceModelManager manager,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('onDeviceModelDelete')),
        content: Text(context.tr('onDeviceModelDeleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) await manager.deleteModel();
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.snapshot});

  final OnDeviceModelSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (snapshot.phase == OnDeviceModelPhase.checking) {
      return const _StatusCard(
        icon: Icons.search_rounded,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
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
                Expanded(child: Text(context.tr('onDeviceModelDownload'))),
                Text(
                  '$percent%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: snapshot.progress,
                minHeight: 8,
                backgroundColor: Holo.surfaceMuted,
              ),
            ),
          ],
        ),
      );
    }
    if (snapshot.phase == OnDeviceModelPhase.ready) {
      return _StatusCard(
        icon: Icons.check_rounded,
        iconColor: const Color(0xFF2D936C),
        iconBackground: const Color(0xFFE7F6EF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('onDeviceModelReady'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (snapshot.backend != null) ...[
              const SizedBox(height: 3),
              Text(
                'Backend · ${snapshot.backend}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Holo.inkPlumSoft),
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
        style: const TextStyle(color: Holo.inkPlum, height: 1.4),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.child,
    this.iconColor = Holo.pink,
    this.iconBackground,
  });

  final IconData icon;
  final Widget child;
  final Color iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Holo.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Holo.border),
        boxShadow: Holo.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground ?? Holo.pink.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

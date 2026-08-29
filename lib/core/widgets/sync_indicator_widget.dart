import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../sync/models/sync_models.dart';
import '../theme/app_theme.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  final bool isCompact;

  const SyncIndicatorWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStateProvider);

    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (syncStatus) {
      case SyncStatus.synced:
        bg = AppTheme.successGreen.withValues(alpha: 0.12);
        fg = AppTheme.successGreen;
        icon = Icons.check_circle_outline;
        label = 'Synced';
        break;
      case SyncStatus.syncing:
        bg = AppTheme.accentGold.withValues(alpha: 0.15);
        fg = const Color(0xFFB45309);
        icon = Icons.sync;
        label = 'Syncing...';
        break;
      case SyncStatus.pending:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade900;
        icon = Icons.cloud_upload_outlined;
        label = 'Pending sync';
        break;
      case SyncStatus.offline:
        bg = Colors.blueGrey.withValues(alpha: 0.12);
        fg = Colors.blueGrey.shade700;
        icon = Icons.cloud_off_outlined;
        label = 'Offline Ready';
        break;
      case SyncStatus.error:
        bg = AppTheme.errorRed.withValues(alpha: 0.12);
        fg = AppTheme.errorRed;
        icon = Icons.error_outline;
        label = 'Sync issue';
        break;
    }

    if (isCompact) {
      return Tooltip(
        message: syncStatus.labelEn,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final engine = ref.read(syncEngineProvider);
            final count = await engine.syncAll();
            if (context.mounted && count > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Synced $count pending operations to cloud!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (syncStatus == SyncStatus.syncing)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                else
                  Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bg,
          child: syncStatus == SyncStatus.syncing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Icon(icon, color: fg),
        ),
        title: Text(
          syncStatus.labelEn,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          syncStatus.labelAm,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            final engine = ref.read(syncEngineProvider);
            final count = await engine.syncAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count > 0
                        ? 'Successfully synced $count items.'
                        : 'Sync completed. Up to date.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}

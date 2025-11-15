import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Dialog that shows detailed sync status information
class SyncStatusDialog extends StatelessWidget {
  const SyncStatusDialog({super.key});

  static void show(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const SyncStatusDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncService, AuthService>(
      builder: (context, syncService, authService, child) {
        final l10n = AppLocalizations.of(context);

        return CupertinoAlertDialog(
          title: Text(l10n?.syncStatusDetails ?? 'Synchronization details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildStatusRow(
                context,
                'État',
                _getStatusText(context, syncService, authService),
                _getStatusColor(syncService, authService),
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                context,
                l10n?.pendingOperations ?? 'Pending operations',
                '${syncService.pendingOperations}',
                syncService.pendingOperations > 0 ? Colors.blue : Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                context,
                l10n?.failedOperations ?? 'Failed operations',
                '${syncService.failedOperations}',
                syncService.failedOperations > 0 ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                context,
                'Dernière sync',
                _getLastSyncText(context, syncService.lastSyncTime),
                Colors.grey,
              ),
              if (syncService.hasError && syncService.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Erreur:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  syncService.lastError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n?.cancel ?? 'Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (syncService.syncEnabled &&
                authService.isAuthenticated &&
                !syncService.isSyncing &&
                (syncService.pendingOperations > 0 || syncService.hasError))
              CupertinoDialogAction(
                child: Text(l10n?.retry ?? 'Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  syncService.forceSyncWithFeedback(context);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _getStatusText(
    BuildContext context,
    SyncService syncService,
    AuthService authService,
  ) {
    final l10n = AppLocalizations.of(context);

    if (!authService.isAuthenticated) {
      return l10n?.syncDisabled ?? 'Disabled';
    }

    if (!syncService.syncEnabled) {
      return l10n?.syncDisabled ?? 'Disabled';
    }

    if (syncService.isSyncing) {
      return l10n?.syncInProgress ?? 'Synchronizing...';
    }

    if (syncService.hasError) {
      return l10n?.syncError ?? 'Error';
    }

    if (syncService.pendingOperations > 0) {
      return 'En attente';
    }

    return l10n?.syncUpToDate ?? 'Up to date';
  }

  Color _getStatusColor(SyncService syncService, AuthService authService) {
    if (!authService.isAuthenticated || !syncService.syncEnabled) {
      return Colors.orange;
    }

    if (syncService.isSyncing) {
      return Colors.blue;
    }

    if (syncService.hasError) {
      return Colors.red;
    }

    if (syncService.pendingOperations > 0) {
      return Colors.blue;
    }

    return Colors.green;
  }

  String _getLastSyncText(BuildContext context, DateTime? lastSyncTime) {
    if (lastSyncTime == null) {
      return AppLocalizations.of(context)?.neverSynced ?? 'Never';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}

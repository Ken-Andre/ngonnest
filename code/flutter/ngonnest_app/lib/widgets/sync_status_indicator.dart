import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Widget that displays the current sync status with appropriate icon and text
class SyncStatusIndicator extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showLastSyncTime;

  const SyncStatusIndicator({
    super.key,
    this.onTap,
    this.showLastSyncTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncService, AuthService>(
      builder: (context, syncService, authService, child) {
        final status = _getSyncStatus(context, syncService, authService);
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status.backgroundColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: status.backgroundColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status.icon,
                  color: status.iconColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (status.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          status.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (showLastSyncTime && status.lastSyncText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          status.lastSyncText!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  SyncStatusData _getSyncStatus(
    BuildContext context,
    SyncService syncService,
    AuthService authService,
  ) {
    final l10n = AppLocalizations.of(context);
    
    // If not authenticated
    if (!authService.isAuthenticated) {
      return SyncStatusData(
        title: l10n?.syncDisabled ?? 'Disabled',
        subtitle: l10n?.connectToEnableSync ?? 'Connect to enable sync',
        icon: CupertinoIcons.cloud,
        iconColor: Colors.orange,
        backgroundColor: Colors.orange,
      );
    }

    // If sync is disabled
    if (!syncService.syncEnabled) {
      return SyncStatusData(
        title: l10n?.syncDisabled ?? 'Disabled',
        subtitle: l10n?.tapForDetails ?? 'Tap for details',
        icon: CupertinoIcons.cloud,
        iconColor: Colors.orange,
        backgroundColor: Colors.orange,
      );
    }

    // If sync is in progress
    if (syncService.isSyncing) {
      return SyncStatusData(
        title: l10n?.syncInProgress ?? '🔄 Synchronizing...',
        subtitle: null,
        icon: CupertinoIcons.arrow_2_circlepath,
        iconColor: Colors.blue,
        backgroundColor: Colors.blue,
        lastSyncText: _getLastSyncText(context, syncService.lastSyncTime),
      );
    }

    // If sync has errors
    if (syncService.hasError) {
      return SyncStatusData(
        title: l10n?.syncError ?? '⚠️ Sync error',
        subtitle: syncService.lastError,
        icon: CupertinoIcons.exclamationmark_triangle,
        iconColor: Colors.red,
        backgroundColor: Colors.red,
        lastSyncText: _getLastSyncText(context, syncService.lastSyncTime),
      );
    }

    // If there are pending operations
    if (syncService.pendingOperations > 0) {
      final pendingText = l10n?.syncPending(syncService.pendingOperations) 
          ?? '⏳ Pending (${syncService.pendingOperations} operations)';
      
      return SyncStatusData(
        title: pendingText,
        subtitle: l10n?.tapForDetails ?? 'Tap for details',
        icon: CupertinoIcons.clock,
        iconColor: Colors.blue,
        backgroundColor: Colors.blue,
        lastSyncText: _getLastSyncText(context, syncService.lastSyncTime),
      );
    }

    // If sync is up to date
    return SyncStatusData(
      title: l10n?.syncUpToDate ?? '✓ Synchronized',
      subtitle: l10n?.tapForDetails ?? 'Tap for details',
      icon: CupertinoIcons.checkmark_circle,
      iconColor: Colors.green,
      backgroundColor: Colors.green,
      lastSyncText: _getLastSyncText(context, syncService.lastSyncTime),
    );
  }

  String? _getLastSyncText(BuildContext context, DateTime? lastSyncTime) {
    if (lastSyncTime == null) {
      return AppLocalizations.of(context)?.neverSynced ?? 'Never synchronized';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);
    
    String timeText;
    if (difference.inMinutes < 1) {
      timeText = 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      timeText = 'il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      timeText = 'il y a ${difference.inHours}h';
    } else {
      timeText = 'il y a ${difference.inDays}j';
    }

    return AppLocalizations.of(context)?.lastSyncTime(timeText) 
        ?? 'Last sync: $timeText';
  }
}

class SyncStatusData {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String? lastSyncText;

  SyncStatusData({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.lastSyncText,
  });
}
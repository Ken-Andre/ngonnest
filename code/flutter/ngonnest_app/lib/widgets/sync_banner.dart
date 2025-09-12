import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/sync_service.dart';

class SyncBanner extends StatefulWidget {
  final DateTime? lastSyncTime;
  final VoidCallback? onTap;
  final bool showErrors;

  const SyncBanner({
    super.key,
    this.lastSyncTime,
    this.onTap,
    this.showErrors = true,
  });

  @override
  State<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<SyncBanner> {
  late DateTime _currentTime;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    // Listen to sync service changes
    _syncService.addListener(_onSyncServiceChanged);

    // Update the current time every second to show real-time sync status
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }

  void _onSyncServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = _syncService.getSyncStatus();
    final lastSyncTime =
        widget.lastSyncTime ?? syncStatus['lastSyncTime'] as DateTime?;
    final isSyncing = syncStatus['isSyncing'] as bool;
    final hasError = syncStatus['hasError'] as bool;
    final lastError = syncStatus['lastError'] as String?;

    if (lastSyncTime == null && !isSyncing && !hasError) {
      return const SizedBox.shrink();
    }

    // Determine banner state
    Color bannerColor;
    Color textColor;
    IconData icon;
    String message;

    if (isSyncing) {
      bannerColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      textColor = Theme.of(context).colorScheme.primary;
      icon = CupertinoIcons.arrow_2_circlepath;
      message = 'Synchronisation en cours...';
    } else if (hasError && widget.showErrors) {
      bannerColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
      textColor = Theme.of(context).colorScheme.error;
      icon = CupertinoIcons.exclamationmark_triangle;
      message = 'Erreur de sync - Appuyez pour réessayer';
    } else if (lastSyncTime != null) {
      final timeSinceSync = _currentTime.difference(lastSyncTime);
      final isStale = timeSinceSync.inSeconds > 30;
      final timeText = _formatTimeSinceSync(timeSinceSync);

      if (isStale) {
        bannerColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
        textColor = Theme.of(context).colorScheme.error;
        icon = CupertinoIcons.exclamationmark_triangle;
        message = 'Dernière sync: $timeText (obsolète)';
      } else {
        bannerColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
        textColor = Theme.of(context).colorScheme.primary;
        icon = CupertinoIcons.checkmark_circle;
        message = 'Dernière sync: $timeText';
      }
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (hasError) {
          _syncService.showSyncErrorDialog(context);
        } else if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _syncService.forceSyncWithFeedback(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeSinceSync(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inDays}j';
    }
  }
}

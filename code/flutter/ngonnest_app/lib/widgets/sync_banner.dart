import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SyncBanner extends StatefulWidget {
  final DateTime? lastSyncTime;
  final VoidCallback? onTap;

  const SyncBanner({
    super.key,
    this.lastSyncTime,
    this.onTap,
  });

  @override
  State<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<SyncBanner> {
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    
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
  Widget build(BuildContext context) {
    if (widget.lastSyncTime == null) {
      return const SizedBox.shrink();
    }

    final timeSinceSync = _currentTime.difference(widget.lastSyncTime!);
    final isStale = timeSinceSync.inSeconds > 30;
    final timeText = _formatTimeSinceSync(timeSinceSync);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isStale 
              ? Theme.of(context).colorScheme.error.withOpacity(0.1)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isStale 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStale ? CupertinoIcons.exclamationmark_triangle : CupertinoIcons.checkmark_circle,
              size: 16,
              color: isStale 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Dernière sync: $timeText',
              style: TextStyle(
                fontSize: 12,
                color: isStale 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
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
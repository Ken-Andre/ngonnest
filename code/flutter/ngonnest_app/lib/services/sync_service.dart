import 'package:flutter/material.dart';

/// Placeholder implementation to satisfy imports during testing.
/// TODO: Replace with actual sync logic when available.
class SyncService extends ChangeNotifier {
  Map<String, dynamic> getSyncStatus() {
    return {
      'lastSyncTime': null,
      'isSyncing': false,
      'hasError': false,
      'lastError': null,
    };
  }

  Future<void> forceSyncWithFeedback(BuildContext context) async {}

  void showSyncErrorDialog(BuildContext context) {}
}

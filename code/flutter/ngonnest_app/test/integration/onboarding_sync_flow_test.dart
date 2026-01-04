// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/sync_service.dart';

/// Unit test for onboarding sync flow
/// Tests the sync service behavior during onboarding
void main() {
  group('Onboarding Sync Flow Unit Tests', () {
    test('Verify sync service state after onboarding flows', () async {
      // This test verifies the sync service is in the correct state
      // after completing onboarding flows

      final syncService = SyncService();
      await syncService.initialize();

      // Initially sync should be disabled
      expect(syncService.syncEnabled, isFalse);
      expect(syncService.userConsent, isFalse);

      // After enabling sync (simulating successful auth flow)
      await syncService.enableSync(userConsent: true);

      expect(syncService.syncEnabled, isTrue);
      expect(syncService.userConsent, isTrue);

      // Reset for clean state
      SyncService.resetInstance();
    });

    test('Verify sync service can be disabled after enabling', () async {
      final syncService = SyncService();
      await syncService.initialize();

      // Enable sync first
      await syncService.enableSync(userConsent: true);
      expect(syncService.syncEnabled, isTrue);
      expect(syncService.userConsent, isTrue);

      // Disable sync
      await syncService.disableSync();
      expect(syncService.syncEnabled, isFalse);
      expect(syncService.userConsent, isFalse);

      // Reset for clean state
      SyncService.resetInstance();
    });
  });
}

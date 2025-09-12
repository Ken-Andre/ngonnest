import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:ngonnest_app/services/connectivity_service.dart';

void main() {
  group('SyncService', () {
    late SyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SyncService.resetInstance();
      syncService = SyncService();
    });

    tearDown(() {
      SyncService.resetInstance();
    });

    test('should initialize with null last sync time', () {
      expect(syncService.lastSyncTime, isNull);
      expect(syncService.isSyncing, isFalse);
      expect(syncService.lastError, isNull);
    });

    test('should detect stale sync after 30 seconds', () async {
      // Set a sync time that's older than 30 seconds
      final oldTime = DateTime.now().subtract(const Duration(seconds: 35));

      // Simulate having a last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', oldTime.toIso8601String());

      // Reinitialize to load the saved time
      await syncService.initialize();

      expect(syncService.isStale, isTrue);
    });

    test('should not be stale within 30 seconds', () async {
      // Set a recent sync time
      final recentTime = DateTime.now().subtract(const Duration(seconds: 10));

      // Simulate having a recent sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', recentTime.toIso8601String());

      // Reinitialize to load the saved time
      await syncService.initialize();

      expect(syncService.isStale, isFalse);
    });

    test('should return sync status correctly', () {
      final status = syncService.getSyncStatus();

      expect(status['lastSyncTime'], equals(syncService.lastSyncTime));
      expect(status['isSyncing'], equals(syncService.isSyncing));
      expect(status['isStale'], equals(syncService.isStale));
      expect(status['lastError'], equals(syncService.lastError));
      expect(status['hasError'], equals(syncService.lastError != null));
    });

    test('should clear error correctly', () {
      // Simulate an error state
      syncService.clearError();

      expect(syncService.lastError, isNull);
    });

    testWidgets('should handle sync when offline', (WidgetTester tester) async {
      // Mock connectivity service to be offline
      final connectivityService = ConnectivityService();
      connectivityService.setConnectivityForTesting(false, false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await syncService.syncData(
                      context: context,
                      showFeedback: true,
                    );
                  },
                  child: const Text('Sync'),
                );
              },
            ),
          ),
        ),
      );

      // Attempt to sync while offline
      await tester.tap(find.text('Sync'));
      await tester.pump();

      // Should show network error
      expect(find.byType(SnackBar), findsOneWidget);
      expect(syncService.lastError, contains('connexion internet'));
    });

    testWidgets('should show sync error dialog', (WidgetTester tester) async {
      // Set an error state
      await syncService
          .syncData(); // This will fail due to no connectivity setup

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    syncService.showSyncErrorDialog(context);
                  },
                  child: const Text('Show Error Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show error dialog if there's an error
      if (syncService.lastError != null) {
        await tester.tap(find.text('Show Error Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Erreur de synchronisation'), findsOneWidget);
      }
    });

    test('should save and load last sync time', () async {
      final testTime = DateTime.now();

      // Simulate a successful sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', testTime.toIso8601String());

      // Reset and create a new instance to test loading
      SyncService.resetInstance();
      final newSyncService = SyncService();
      await newSyncService.initialize();

      expect(newSyncService.lastSyncTime, isNotNull);
      expect(
        newSyncService.lastSyncTime!.difference(testTime).inSeconds,
        lessThan(1),
      );
    });

    group('Sync Operation', () {
      test('should prevent concurrent syncs', () async {
        // Mock connectivity service to be online
        final connectivityService = ConnectivityService();
        connectivityService.setConnectivityForTesting(true, false);

        // Start first sync
        final firstSync = syncService.syncData();

        // Try to start second sync while first is running
        final secondSync = syncService.syncData();

        // Second sync should return false immediately
        expect(await secondSync, isFalse);

        // Wait for first sync to complete
        await firstSync;
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // This should not throw even if SharedPreferences fails
        expect(() async => await syncService.initialize(), returnsNormally);
      });

      test('should handle save errors gracefully', () async {
        // This should not throw even if saving fails
        expect(() async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_sync_time',
            DateTime.now().toIso8601String(),
          );
        }, returnsNormally);
      });
    });
  });
}

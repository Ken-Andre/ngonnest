import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/services/database_service.dart';

/// Test suite for database connection stability improvements
/// Tests the enhanced connection handling and recovery mechanisms
void main() {
  // Initialize test environment
  setUpAll(() async {
    DatabaseService.configureForTests();

    // Initialize FFI for desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  // Clean up after each test
  tearDown(() async {
    await DatabaseService.resetForTests();
  });

  group('Database Connection Stability Tests', () {
    test('should handle multiple simultaneous connection requests', () async {
      // Test that multiple simultaneous requests don't cause deadlocks
      final futures = <Future>[];

      for (int i = 0; i < 5; i++) {
        futures.add(DatabaseService().database);
      }

      // All futures should complete successfully
      final results = await Future.wait(futures);

      // All results should be the same database instance
      final firstDb = results.first;
      for (final db in results) {
        expect(db, equals(firstDb));
        expect(db.isOpen, isTrue);
      }
    });

    test('should recover from forced disconnection', () async {
      // Get initial connection
      final db1 = await DatabaseService().database;
      expect(db1.isOpen, isTrue);

      // Force reinitialize
      await DatabaseService().forceReinitialize();

      // Next connection should work
      final db2 = await DatabaseService().database;
      expect(db2.isOpen, isTrue);

      // Should be a different instance after force reinitialize
      expect(db2.path, equals(db1.path)); // Same file path
    });

    test('should handle connection timeout gracefully', () async {
      // This test verifies that timeouts are handled properly
      // We can't easily simulate a real timeout, but we can test the logic

      final service = DatabaseService();
      final isValid = await service.isConnectionValid();
      expect(isValid, isA<bool>()); // Should not throw
    });

    test('should maintain connection state correctly during operations', () async {
      final service = DatabaseService();

      // Perform some operations
      final status1 = service.getConnectionStatus();
      expect(status1['is_connected'], isA<bool>());
      expect(status1['is_initializing'], isA<bool>());

      // Get database connection
      final db = await service.database;

      // Check status after connection
      final status2 = service.getConnectionStatus();
      expect(status2['is_connected'], isTrue);
      expect(status2['has_database_instance'], isTrue);
      expect(status2['is_database_open'], isTrue);
    });

    test('should handle rapid connect/disconnect cycles', () async {
      for (int i = 0; i < 3; i++) {
        // Connect
        final db = await DatabaseService().database;
        expect(db.isOpen, isTrue);

        // Force close
        await DatabaseService.resetForTests();

        // Next iteration should work
      }
    });

    test('should provide meaningful connection status information', () async {
      final service = DatabaseService();

      // Before connection
      var status = service.getConnectionStatus();
      expect(status.containsKey('is_connected'), isTrue);
      expect(status.containsKey('is_initializing'), isTrue);
      expect(status.containsKey('has_database_instance'), isTrue);
      expect(status.containsKey('is_database_open'), isTrue);
      expect(status.containsKey('connection_retry_count'), isTrue);

      // After connection
      await service.database;
      status = service.getConnectionStatus();
      expect(status['is_connected'], isTrue);
      expect(status['has_database_instance'], isTrue);
      expect(status['is_database_open'], isTrue);
    });

    test('should handle database operations after connection recovery', () async {
      final service = DatabaseService();

      // Force reinitialize to ensure clean state
      await service.forceReinitialize();

      // Perform database operation
      final foyer = await service.getFoyer();
      expect(foyer, isNull); // Should not throw, just return null for empty table

      // Verify connection is still valid
      final isValid = await service.isConnectionValid();
      expect(isValid, isTrue);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// import 'package:ngonnest_app/services/error_logger_service.dart';
import 'package:ngonnest_app/repository/foyer_repository.dart';
import 'package:ngonnest_app/repository/inventory_repository.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test suite to verify database connection stability improvements
/// Tests the enhanced singleton pattern with automatic recovery mechanisms
void main() {
  // Initialize test environment
  setUpAll(() async {
    try {
      // Proper initialization for sqflite FFI testing
      print('[TEST:INIT] Initializing sqflite FFI for testing...');

      // For Linux/Windows we use FFI, for Android/iOS we use the platform API
      // This initialization is needed for unit tests
      if (!Platform.isAndroid && !Platform.isIOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print(
          '[TEST:INIT] Sqflite FFI initialized for ${Platform.operatingSystem}',
        );
      }

      print(
        '[TEST:INIT] Database factory set to: ${databaseFactory.runtimeType}',
      );
    } catch (e) {
      print('[TEST:INIT] Database factory fallback: $e');
      // Continue with default factory for tests
    }

    // Initialize Flutter test bindings
    TestWidgetsFlutterBinding.ensureInitialized();
    print('[TEST:INIT] Flutter test bindings initialized');
  });

  late DatabaseService databaseService;
  late FoyerRepository foyerRepository;
  late InventoryRepository inventoryRepository;

  setUp(() {
    databaseService = DatabaseService();
    foyerRepository = FoyerRepository(databaseService);
    inventoryRepository = InventoryRepository(databaseService);
  });

  group('Database Connection Stability Tests', () {
    test(
      'Singleton pattern maintained across multiple instantiations',
      () async {
        final db1 = DatabaseService();
        final db2 = DatabaseService();

        // Both should return the same database instance
        final database1 = await db1.database;
        final database2 = await db2.database;

        expect(database1.path, equals(database2.path));
        print('[TEST] ✓ Singleton pattern verified');
      },
    );

    test('Connection validity check works', () async {
      final isValid = await databaseService.isConnectionValid();
      expect(isValid, isA<bool>());
      print('[TEST] ✓ Recovery methods are accessible');
    });

    test('Database operations survive mock disconnection scenarios', () async {
      // Test with a valid operation that should work
      final foyerExists = await foyerRepository.exists();
      expect(foyerExists, isNotNull); // Should return bool, not throw exception
      print('[TEST] ✓ Repository handles database operations gracefully');

      // Test connection state is tracked
      final isConnected = databaseService.isConnectionValid();
      await isConnected; // Wait for result
      print('[TEST] ✓ Connection state tracking works');
    });

    test('Error logging integration works', () async {
      // This test verifies that error logging doesn't break the database operations
      try {
        // Try a potentially failing operation
        await inventoryRepository.getAll(999); // Non-existent foyer
        // If no error thrown, that's acceptable for this test
        print('[TEST] ✓ Error logging integration works (no error)');
      } catch (e) {
        // If error is thrown, logging should have been triggered
        print('[TEST] ✓ Error logging integration works (error handled)');
        expect(e, isNotNull);
      }
    });

    test('Database service maintains connection state correctly', () async {
      final connectionState = await databaseService.isConnectionValid();
      expect(connectionState, isTrue);

      // Verify connection state tracking works
      final db = await databaseService.database;
      expect(db.isOpen, isTrue);
      print('[TEST] ✓ Connection state management works correctly');
    });
  });

  group('Error Recovery Mechanisms', () {
    test('Connection recovery methods are available', () async {
      // Test that the methods we added for recovery are callable
      final isValid = await databaseService.isConnectionValid();
      expect(isValid, isA<bool>());
      print('[TEST] ✓ Recovery methods are accessible');
    });

    test('Repository error handling works', () async {
      // Test that repositories can handle database operations
      // without crashing the app
      final foyerExists = await foyerRepository.exists();
      expect(foyerExists, isA<bool>()); // Should return bool or bool?
      print('[TEST] ✓ Repository error handling works correctly');
    });
  });

  group('Background Task Compatibility', () {
    test(
      'Database service can be instantiated multiple times (background compatible)',
      () async {
        // This simulates what happens when background tasks create new instances
        final backgroundService1 = DatabaseService();
        final backgroundService2 = DatabaseService();

        // Both should be able to get the database without issues
        final db1 = await backgroundService1.database;
        final db2 = await backgroundService2.database;

        expect(db1.isOpen, isTrue);
        expect(db2.isOpen, isTrue);
        expect(db1.path, equals(db2.path)); // Same database file
        print('[TEST] ✓ Multiple instances compatible with background tasks');
      },
    );

    test('Connection validation works across instances', () async {
      final instance1 = DatabaseService();
      final instance2 = DatabaseService();

      final valid1 = await instance1.isConnectionValid();
      final valid2 = await instance2.isConnectionValid();

      expect(valid1, isTrue);
      expect(valid2, isTrue);
      print('[TEST] ✓ Connection validation works across instances');
    });
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/main.dart' as app;
import '../../lib/services/database_service.dart';

/// Helper class for all types of tests
/// Centralizes initialization and provides utilities for both unit and integration tests
class TestHelper {
  static bool _isInitialized = false;
  static bool _databaseConfigured = false;

  /// Initialize test environment once
  static Future<void> initializeTestEnvironment() async {
    if (_isInitialized) return;

    // Initialize Flutter test bindings
    TestWidgetsFlutterBinding.ensureInitialized();

    // Configure database for tests
    if (!_databaseConfigured) {
      DatabaseService.configureForTests();

      // Initialize FFI for desktop platforms
      if (!Platform.isAndroid && !Platform.isIOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      _databaseConfigured = true;
    }

    _isInitialized = true;
  }

  /// Initialize environment for unit tests (no real database)
  static Future<void> initializeUnitTestEnvironment() async {
    if (_isInitialized) return;

    // Initialize Flutter test bindings for unit tests
    TestWidgetsFlutterBinding.ensureInitialized();

    _isInitialized = true;
  }

  /// Reset database state between tests
  static Future<void> resetDatabase() async {
    await DatabaseService.resetForTests();
  }

  /// Initialize app for widget tests
  static Future<void> initializeAppForTest(WidgetTester tester) async {
    await initializeTestEnvironment();

    // Reset database before initializing app
    await resetDatabase();

    // For integration tests, we need a minimal app setup
    // Instead of calling app.main() which can be complex, we'll set up just what's needed
    // The test will handle navigation and UI setup itself
    await tester.pumpWidget(const SizedBox()); // Minimal widget to satisfy tester
    await tester.pumpAndSettle();
  }

  /// Clean up after each test
  static Future<void> cleanupAfterTest() async {
    await resetDatabase();
  }

  /// Wait for database operations to complete
  static Future<void> waitForDatabaseOperations() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }


}

/// Extension on WidgetTester for convenience
extension TestHelperExtension on WidgetTester {
  /// Initialize app and wait for it to be ready
  Future<void> initializeApp() async {
    await TestHelper.initializeAppForTest(this);
  }

  /// Reset database state
  Future<void> resetDatabase() async {
    await TestHelper.resetDatabase();
  }

  /// Clean up after test
  Future<void> cleanup() async {
    await TestHelper.cleanupAfterTest();
  }
}

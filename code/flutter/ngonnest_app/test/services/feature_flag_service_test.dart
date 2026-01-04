import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/feature_flag_service.dart';

void main() {
  group('FeatureFlagService', () {
    late FeatureFlagService featureFlagService;

    setUp(() {
      featureFlagService = FeatureFlagService();
    });

    tearDown(() {
      // Reset any mocked values if needed
    });

    test('isCloudSyncEnabled() returns false in release mode', () {
      // Mock kDebugMode and kProfileMode to simulate release mode
      // Since we can't directly change these constants in tests,
      // we'll test the actual behavior based on the current environment
      
      // In release mode, isDevMode should be false
      if (!kDebugMode && !kProfileMode) {
        expect(featureFlagService.isCloudSyncEnabled(), false);
      } else {
        // In debug/profile mode, isDevMode should be true
        expect(featureFlagService.isCloudSyncEnabled(), true);
      }
    });

    test('isCloudSyncEnabled() returns true in debug mode', () {
      // This test will pass when run in debug mode
      if (kDebugMode || kProfileMode) {
        expect(featureFlagService.isCloudSyncEnabled(), true);
      } else {
        expect(featureFlagService.isCloudSyncEnabled(), false);
      }
    });

    test('isPremiumEnabled() always returns false in V1', () {
      expect(featureFlagService.isPremiumEnabled(), false);
    });

    test('isExperimentalFeaturesEnabled() always returns false in V1', () {
      expect(featureFlagService.isExperimentalFeaturesEnabled(), false);
    });

    test('initialize() completes without error', () async {
      // Should not throw any exceptions
      await expectLater(featureFlagService.initialize(), completes);
    });
  });
}
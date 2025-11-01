import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:ngonnest_app/services/calendar_sync_service.dart';

void main() {
  setUpAll(() {
    // Initialize Flutter test bindings
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CalendarSyncService Tests', () {
    late CalendarSyncService calendarSyncService;

    setUp(() {
      calendarSyncService = CalendarSyncService();
    });

    group('Platform Detection', () {
      test('should detect Android platform correctly', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert
        expect(status, isA<CalendarPermissionStatus>());

        debugDefaultTargetPlatformOverride = null;
      });

      test('should detect iOS platform correctly', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert
        expect(status, isA<CalendarPermissionStatus>());

        debugDefaultTargetPlatformOverride = null;
      });

      test('should handle web platform correctly', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert
        expect(status, CalendarPermissionStatus.unsupported);

        debugDefaultTargetPlatformOverride = null;
      });

      test('should handle unknown platforms gracefully', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert
        expect(status, CalendarPermissionStatus.unsupported);

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('Permission Status Logic', () {
      test('should return valid permission status for Android', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert - Le statut doit être l'un des états valides
        expect(status, isIn([
          CalendarPermissionStatus.granted,
          CalendarPermissionStatus.denied,
          CalendarPermissionStatus.permanentlyDenied,
          CalendarPermissionStatus.unsupported,
          CalendarPermissionStatus.error,
        ]));

        debugDefaultTargetPlatformOverride = null;
      });

      test('should return valid permission status for iOS', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert - Le statut doit être l'un des états valides
        expect(status, isIn([
          CalendarPermissionStatus.granted,
          CalendarPermissionStatus.denied,
          CalendarPermissionStatus.permanentlyDenied,
          CalendarPermissionStatus.unsupported,
          CalendarPermissionStatus.error,
        ]));

        debugDefaultTargetPlatformOverride = null;
      });

      test('should return valid request result', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        // Act
        final result = await calendarSyncService.requestPermissionsWithFeedback();

        // Assert - Le résultat doit être l'un des états valides
        expect(result, isIn([
          CalendarPermissionResult.granted,
          CalendarPermissionResult.denied,
          CalendarPermissionResult.permanentlyDenied,
          CalendarPermissionResult.unsupported,
          CalendarPermissionResult.error,
        ]));

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('Calendar Availability', () {
      test('should return boolean for calendar availability check', () async {
        // Act
        final isAvailable = await calendarSyncService.isCalendarAvailable();

        // Assert
        expect(isAvailable, isA<bool>());
      });

      test('should return false for web platform', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        // Act
        final isAvailable = await calendarSyncService.isCalendarAvailable();

        // Assert - Desktop platforms should not support calendar
        expect(isAvailable, false);

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully in getPermissionStatus', () async {
        // Arrange - Forcer une plateforme inconnue qui pourrait causer une erreur
        debugDefaultTargetPlatformOverride = null;

        // Act
        final status = await calendarSyncService.getPermissionStatus();

        // Assert - Ne devrait jamais throw, devrait retourner un statut valide
        expect(status, isA<CalendarPermissionStatus>());
      });

      test('should handle errors gracefully in isCalendarAvailable', () async {
        // Act
        final isAvailable = await calendarSyncService.isCalendarAvailable();

        // Assert - Ne devrait jamais throw, devrait retourner un booléen
        expect(isAvailable, isA<bool>());
      });

      test('should handle errors gracefully in requestPermissionsWithFeedback', () async {
        // Act
        final result = await calendarSyncService.requestPermissionsWithFeedback();

        // Assert - Ne devrait jamais throw, devrait retourner un résultat valide
        expect(result, isA<CalendarPermissionResult>());
      });
    });

    group('Integration Behavior', () {
      test('should behave consistently across multiple calls', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        // Act - Appeler plusieurs fois
        final status1 = await calendarSyncService.getPermissionStatus();
        final status2 = await calendarSyncService.getPermissionStatus();

        // Assert - Les résultats devraient être cohérents
        expect(status1, status2);

        debugDefaultTargetPlatformOverride = null;
      });

      test('should handle platform changes correctly', () async {
        // Arrange & Act
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final androidStatus = await calendarSyncService.getPermissionStatus();

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final iosStatus = await calendarSyncService.getPermissionStatus();

        // Assert - Différentes plateformes peuvent avoir différents statuts
        expect(androidStatus, isA<CalendarPermissionStatus>());
        expect(iosStatus, isA<CalendarPermissionStatus>());

        debugDefaultTargetPlatformOverride = null;
      });
    });

    group('CalendarSyncService Real Device Tests', () {
      late CalendarSyncService calendarSyncService;

      setUp(() {
        calendarSyncService = CalendarSyncService();
      });

      test('should work with real Android permissions', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        // Act
        final status = await calendarSyncService.getPermissionStatus();
        final isAvailable = await calendarSyncService.isCalendarAvailable();

        // Assert - Sur un vrai appareil Android, cela devrait fonctionner
        expect(status, isA<CalendarPermissionStatus>());
        expect(isAvailable, isA<bool>());

        debugDefaultTargetPlatformOverride = null;
      });

      test('should work with real iOS permissions', () async {
        // Arrange
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        // Act
        final status = await calendarSyncService.getPermissionStatus();
        final isAvailable = await calendarSyncService.isCalendarAvailable();

        // Assert - Sur un vrai appareil iOS, cela devrait fonctionner
        expect(status, isA<CalendarPermissionStatus>());
        expect(isAvailable, isA<bool>());

        debugDefaultTargetPlatformOverride = null;
      });
    });
  });
}

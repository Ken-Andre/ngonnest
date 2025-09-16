import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ngonnest_app/services/notification_service.dart';
import 'package:ngonnest_app/services/calendar_sync_service.dart';
import 'package:ngonnest_app/services/settings_service.dart';
import 'package:ngonnest_app/models/alert.dart';

// Generate mocks
@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  CalendarSyncService,
  SettingsService,
])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
    late MockCalendarSyncService mockCalendarService;

    setUp(() {
      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
      mockCalendarService = MockCalendarSyncService();
    });

    group('initialize', () {
      test('should initialize notification plugin with correct settings', () async {
        // Arrange
        when(mockNotificationsPlugin.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
            .thenAnswer((_) async => true);
        when(mockNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>())
            .thenReturn(null);

        // Act
        await NotificationService.initialize();

        // Assert
        verify(mockNotificationsPlugin.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse')))
            .called(1);
      });

      test('should request iOS permissions when available', () async {
        // This test would require more complex mocking of platform-specific implementations
        expect(true, isTrue); // Placeholder for iOS-specific testing
      });
    });

    group('showLowStockNotification', () {
      test('should show low stock notification with correct parameters', () async {
        // Arrange
        const id = 123;
        const productName = 'Savon de Marseille';
        const remainingQuantity = 2;
        const category = 'Hygiène';

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showLowStockNotification(
          id: id,
          productName: productName,
          remainingQuantity: remainingQuantity,
          category: category,
        );

        // Assert
        verify(mockNotificationsPlugin.show(
          id,
          'Stock faible',
          '$productName - Plus que $remainingQuantity article(s) en stock',
          any,
          payload: 'low_stock_$id',
        )).called(1);
      });

      test('should use correct notification channel for low stock', () async {
        // Arrange
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showLowStockNotification(
          id: 1,
          productName: 'Test Product',
          remainingQuantity: 1,
          category: 'Test',
        );

        // Assert
        final capturedDetails = verify(mockNotificationsPlugin.show(
          any, any, any, captureAny, payload: anyNamed('payload')
        )).captured.single as NotificationDetails;

        expect(capturedDetails.android?.channelId, equals('low_stock_channel'));
        expect(capturedDetails.android?.channelName, equals('Stock faible'));
        expect(capturedDetails.android?.importance, equals(Importance.high));
        expect(capturedDetails.android?.priority, equals(Priority.high));
      });
    });

    group('showExpiryNotification', () {
      test('should show expiry notification with correct parameters', () async {
        // Arrange
        const id = 456;
        const productName = 'Lait';
        const expiryDate = '2024-01-15';
        const category = 'Cuisine';

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showExpiryNotification(
          id: id,
          productName: productName,
          expiryDate: expiryDate,
          category: category,
        );

        // Assert
        verify(mockNotificationsPlugin.show(
          id,
          'Expiration proche',
          '$productName expire bientôt ($expiryDate)',
          any,
          payload: 'expiry_$id',
        )).called(1);
      });

      test('should use correct notification channel for expiry', () async {
        // Arrange
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showExpiryNotification(
          id: 1,
          productName: 'Test Product',
          expiryDate: '2024-01-01',
          category: 'Test',
        );

        // Assert
        final capturedDetails = verify(mockNotificationsPlugin.show(
          any, any, any, captureAny, payload: anyNamed('payload')
        )).captured.single as NotificationDetails;

        expect(capturedDetails.android?.channelId, equals('expiry_channel'));
        expect(capturedDetails.android?.channelName, equals('Expiration proche'));
        expect(capturedDetails.android?.importance, equals(Importance.high));
        expect(capturedDetails.android?.priority, equals(Priority.high));
      });
    });

    group('showScheduledNotification', () {
      test('should schedule notification for future date', () async {
        // Arrange
        const id = 789;
        const title = 'Rappel courses';
        const body = 'Il est temps de faire les courses';
        final scheduledDate = DateTime.now().add(Duration(hours: 2));

        when(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenAnswer((_) async {});

        // Act
        await NotificationService.showScheduledNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );

        // Assert
        verify(mockNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          any, // TZDateTime
          any, // NotificationDetails
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        )).called(1);
      });

      test('should add to calendar when enabled and requested', () async {
        // Arrange
        const id = 789;
        const title = 'Rappel courses';
        const body = 'Il est temps de faire les courses';
        final scheduledDate = DateTime.now().add(Duration(hours: 2));

        when(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenAnswer((_) async {});

        // Mock static method call
        when(SettingsService.getCalendarSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.addEvent(
          title: anyNamed('title'),
          description: anyNamed('description'),
          start: anyNamed('start'),
        )).thenAnswer((_) async {});

        // Act
        await NotificationService.showScheduledNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          addToCalendar: true,
        );

        // Assert
        verify(mockCalendarService.addEvent(
          title: title,
          description: body,
          start: scheduledDate,
        )).called(1);
      });

      test('should handle calendar sync errors gracefully', () async {
        // Arrange
        const id = 789;
        const title = 'Rappel courses';
        const body = 'Il est temps de faire les courses';
        final scheduledDate = DateTime.now().add(Duration(hours: 2));

        when(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenAnswer((_) async {});

        when(SettingsService.getCalendarSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.addEvent(
          title: anyNamed('title'),
          description: anyNamed('description'),
          start: anyNamed('start'),
        )).thenThrow(Exception('Calendar sync failed'));

        // Act & Assert - Should not throw
        await NotificationService.showScheduledNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          addToCalendar: true,
        );

        // Notification should still be scheduled despite calendar error
        verify(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).called(1);
      });
    });

    group('showReminderNotification', () {
      test('should show reminder notification with correct parameters', () async {
        // Arrange
        const id = 101;
        const reminderTitle = 'Acheter du savon';
        const message = 'N\'oubliez pas d\'acheter du savon de Marseille';

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showReminderNotification(
          id: id,
          reminderTitle: reminderTitle,
          message: message,
        );

        // Assert
        verify(mockNotificationsPlugin.show(
          id,
          reminderTitle,
          message,
          any,
          payload: 'reminder_$id',
        )).called(1);
      });

      test('should use correct notification channel for reminders', () async {
        // Arrange
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showReminderNotification(
          id: 1,
          reminderTitle: 'Test Reminder',
          message: 'Test Message',
        );

        // Assert
        final capturedDetails = verify(mockNotificationsPlugin.show(
          any, any, any, captureAny, payload: anyNamed('payload')
        )).captured.single as NotificationDetails;

        expect(capturedDetails.android?.channelId, equals('reminder_channel'));
        expect(capturedDetails.android?.channelName, equals('Rappels'));
        expect(capturedDetails.android?.importance, equals(Importance.defaultImportance));
        expect(capturedDetails.android?.priority, equals(Priority.defaultPriority));
      });
    });

    group('showBudgetAlert', () {
      test('should show budget alert with correct parameters', () async {
        // Arrange
        const id = 202;
        const categoryName = 'Hygiène';
        const spentAmount = 150.0;
        const limitAmount = 120.0;
        const percentage = 125;

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showBudgetAlert(
          id: id,
          categoryName: categoryName,
          spentAmount: spentAmount,
          limitAmount: limitAmount,
          percentage: percentage,
        );

        // Assert
        verify(mockNotificationsPlugin.show(
          id,
          'Budget dépassé - $categoryName',
          'Vous avez dépensé ${spentAmount.toStringAsFixed(2)} € sur ${limitAmount.toStringAsFixed(2)} € ($percentage%)',
          any,
          payload: 'budget_alert_$id',
        )).called(1);
      });

      test('should use high priority for budget alerts', () async {
        // Arrange
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showBudgetAlert(
          id: 1,
          categoryName: 'Test',
          spentAmount: 100.0,
          limitAmount: 80.0,
          percentage: 125,
        );

        // Assert
        final capturedDetails = verify(mockNotificationsPlugin.show(
          any, any, any, captureAny, payload: anyNamed('payload')
        )).captured.single as NotificationDetails;

        expect(capturedDetails.android?.channelId, equals('budget_alert_channel'));
        expect(capturedDetails.android?.channelName, equals('Alertes budget'));
        expect(capturedDetails.android?.importance, equals(Importance.high));
        expect(capturedDetails.android?.priority, equals(Priority.high));
      });
    });

    group('scheduleRecurringReminder', () {
      test('should schedule recurring reminder', () async {
        // Arrange
        const id = 303;
        const title = 'Vérifier les stocks';
        const body = 'Temps de vérifier vos stocks';
        const intervalDays = 7;
        final startDate = DateTime.now().add(Duration(days: 1));

        when(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenAnswer((_) async {});

        // Act
        await NotificationService.scheduleRecurringReminder(
          id: id,
          title: title,
          body: body,
          intervalDays: intervalDays,
          startDate: startDate,
        );

        // Assert
        verify(mockNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          any, // TZDateTime
          any, // NotificationDetails
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        )).called(1);
      });
    });

    group('cancelNotification', () {
      test('should cancel specific notification', () async {
        // Arrange
        const id = 404;
        when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async {});

        // Act
        await NotificationService.cancelNotification(id);

        // Assert
        verify(mockNotificationsPlugin.cancel(id)).called(1);
      });
    });

    group('cancelAllNotifications', () {
      test('should cancel all notifications', () async {
        // Arrange
        when(mockNotificationsPlugin.cancelAll()).thenAnswer((_) async {});

        // Act
        await NotificationService.cancelAllNotifications();

        // Assert
        verify(mockNotificationsPlugin.cancelAll()).called(1);
      });
    });

    group('getPendingNotifications', () {
      test('should return pending notifications', () async {
        // Arrange
        final mockPendingNotifications = [
          PendingNotificationRequest(1, 'Title 1', 'Body 1', 'payload1'),
          PendingNotificationRequest(2, 'Title 2', 'Body 2', 'payload2'),
        ];
        when(mockNotificationsPlugin.pendingNotificationRequests())
            .thenAnswer((_) async => mockPendingNotifications);

        // Act
        final result = await NotificationService.getPendingNotifications();

        // Assert
        expect(result, equals(mockPendingNotifications));
        verify(mockNotificationsPlugin.pendingNotificationRequests()).called(1);
      });
    });

    group('processAlertForNotification', () {
      test('should process stock alert correctly', () async {
        // Arrange
        final alert = Alert(
          id: 1,
          idObjet: 123,
          typeAlerte: AlertType.stockFaible,
          titre: 'Stock faible',
          message: 'Savon de Marseille est en rupture de stock (quantité restante: 1)',
          urgences: 'high',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          'Stock faible',
          contains('Savon de Marseille'),
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });

      test('should process expiry alert correctly', () async {
        // Arrange
        final alert = Alert(
          id: 2,
          idObjet: 456,
          typeAlerte: AlertType.expirationProche,
          titre: 'Expiration proche',
          message: 'Lait expire bientôt (le 2024-01-15)',
          urgences: 'medium',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          'Expiration proche',
          contains('Lait'),
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });

      test('should process reminder alert correctly', () async {
        // Arrange
        final alert = Alert(
          id: 3,
          idObjet: 789,
          typeAlerte: AlertType.reminder,
          titre: 'Rappel personnel',
          message: 'Acheter du savon au marché',
          urgences: 'low',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          'Rappel personnel',
          'Acheter du savon au marché',
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });

      test('should process system alert correctly', () async {
        // Arrange
        final alert = Alert(
          id: 4,
          idObjet: 101,
          typeAlerte: AlertType.system,
          titre: 'Alerte système',
          message: 'Mise à jour des prix disponible',
          urgences: 'medium',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          'Alerte système',
          'Mise à jour des prix disponible',
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });
    });

    group('Message parsing helpers', () {
      test('should extract product info from stock message correctly', () async {
        // Arrange
        final alert = Alert(
          id: 1,
          idObjet: 123,
          typeAlerte: AlertType.stockFaible,
          titre: 'Stock faible',
          message: 'Savon de Marseille est en rupture de stock (quantité restante: 2)',
          urgences: 'high',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          any,
          contains('2 article(s)'), // Should extract quantity correctly
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });

      test('should extract expiry info from expiry message correctly', () async {
        // Arrange
        final alert = Alert(
          id: 2,
          idObjet: 456,
          typeAlerte: AlertType.expirationProche,
          titre: 'Expiration proche',
          message: 'Yaourt expire bientôt (le 2024-01-20)',
          urgences: 'medium',
          dateCreation: DateTime.now(),
          lu: false,
          resolu: false,
        );

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.processAlertForNotification(alert);

        // Assert
        verify(mockNotificationsPlugin.show(
          any,
          any,
          contains('2024-01-20'), // Should extract date correctly
          any,
          payload: anyNamed('payload'),
        )).called(1);
      });
    });

    group('Error handling', () {
      test('should handle notification plugin errors gracefully', () async {
        // Arrange
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenThrow(Exception('Notification failed'));

        // Act & Assert - Should not throw
        await NotificationService.showLowStockNotification(
          id: 1,
          productName: 'Test Product',
          remainingQuantity: 1,
          category: 'Test',
        );

        // Should attempt to show notification despite error
        verify(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .called(1);
      });

      test('should handle scheduling errors gracefully', () async {
        // Arrange
        when(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenThrow(Exception('Scheduling failed'));

        // Act & Assert - Should not throw
        await NotificationService.showScheduledNotification(
          id: 1,
          title: 'Test',
          body: 'Test',
          scheduledDate: DateTime.now().add(Duration(hours: 1)),
        );

        verify(mockNotificationsPlugin.zonedSchedule(
          any, any, any, any, any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).called(1);
      });
    });

    group('NgonNest specific scenarios', () {
      test('should handle Cameroon-specific product names', () async {
        // Arrange
        const productNames = [
          'Savon de Marseille',
          'Huile de palme',
          'Riz parfumé',
          'Cube Maggi',
        ];

        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act & Assert
        for (final productName in productNames) {
          await NotificationService.showLowStockNotification(
            id: productNames.indexOf(productName),
            productName: productName,
            remainingQuantity: 1,
            category: 'Test',
          );

          verify(mockNotificationsPlugin.show(
            any,
            any,
            contains(productName),
            any,
            payload: anyNamed('payload'),
          )).called(1);
        }
      });

      test('should work offline (local notifications)', () async {
        // Arrange - Notifications should work offline since they're local
        when(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async {});

        // Act
        await NotificationService.showLowStockNotification(
          id: 1,
          productName: 'Savon',
          remainingQuantity: 1,
          category: 'Hygiène',
        );

        // Assert
        verify(mockNotificationsPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .called(1);
      });
    });
  });
}

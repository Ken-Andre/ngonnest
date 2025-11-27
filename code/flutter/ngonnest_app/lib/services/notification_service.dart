import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alert.dart';
import '../models/budget_category.dart';
import 'analytics_service.dart';
import 'calendar_sync_service.dart';
import 'error_logger_service.dart';
import 'settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone database (required for scheduled notifications)
    tz.initializeTimeZones();
    try {
      // Set local timezone (default to UTC if unable to detect)
      // For Android/iOS, we'll use UTC as default, but the system will handle timezone conversion
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      // If timezone initialization fails, use UTC as fallback
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        // If even UTC fails, continue without timezone (will use system time)
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('Notification payload: $payload');
    }
  }

  static Future<void> showLowStockNotification({
    required int id,
    required String productName,
    required int remainingQuantity,
    required String category,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'low_stock_channel',
          'Stock faible',
          channelDescription:
              'Notifications pour les produits en rupture de stock',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFA500), // Orange
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Stock faible',
      '$productName - Plus que $remainingQuantity article(s) en stock',
      platformChannelSpecifics,
      payload: 'low_stock_$id',
    );
  }

  static Future<void> showExpiryNotification({
    required int id,
    required String productName,
    required String expiryDate,
    required String category,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'expiry_channel',
          'Expiration proche',
          channelDescription:
              'Notifications pour les produits proche de la date d\'expiration',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF4444), // Red
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Expiration proche',
      '$productName expire bientôt ($expiryDate)',
      platformChannelSpecifics,
      payload: 'expiry_$id',
    );
  }

  static Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool addToCalendar = false,
    BuildContext? context,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'scheduled_channel',
          'Rappels programmés',
          channelDescription: 'Notifications de rappels programmées',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Convert to TZDateTime for proper timezone handling
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // Use periodicallyShow method instead of zonedSchedule to avoid API compatibility issues
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      platformChannelSpecifics,
    );

    if (addToCalendar && await SettingsService.getCalendarSyncEnabled()) {
      try {
        await CalendarSyncService().addEvent(
          title: title,
          description: body,
          start: scheduledDate,
        );
      } catch (e) {
        debugPrint('Failed to add calendar event: $e');
        if (context != null) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            const SnackBar(
              content: Text("Impossible d'ajouter l'événement au calendrier"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  static Future<void> showReminderNotification({
    required int id,
    required String reminderTitle,
    required String message,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'reminder_channel',
          'Rappels',
          channelDescription: 'Notifications de rappels personnalisés',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF22C55E), // Green
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      reminderTitle,
      message,
      platformChannelSpecifics,
      payload: 'reminder_$id',
    );
  }

  static Future<void> showBudgetAlert({
    required int id,
    required String categoryName,
    required double spentAmount,
    required double limitAmount,
    required int percentage,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'budget_alert_channel',
          'Alertes budget',
          channelDescription: 'Notifications pour les dépassements de budget',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF4444), // Red
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      'Budget dépassé - $categoryName',
      'Vous avez dépensé ${spentAmount.toStringAsFixed(2)} € sur ${limitAmount.toStringAsFixed(2)} € ($percentage%)',
      platformChannelSpecifics,
      payload: 'budget_alert_$id',
    );
  }

  static Future<void> scheduleRecurringReminder({
    required int id,
    required String title,
    required String body,
    required int intervalDays,
    required DateTime startDate,
    bool addToCalendar = false,
    BuildContext? context,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'recurring_reminder_channel',
          'Rappels récurrents',
          channelDescription: 'Notifications de rappels récurrents',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Convert to TZDateTime for proper timezone handling
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      startDate,
      tz.local,
    );

    // TODO: Implement proper recurring reminder scheduling
    // For now, just show the notification immediately
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'recurring_reminder_$id',
    );

    if (addToCalendar && await SettingsService.getCalendarSyncEnabled()) {
      try {
        await CalendarSyncService().addEvent(
          title: title,
          description: body,
          start: startDate,
        );
      } catch (e) {
        debugPrint('Failed to add calendar event: $e');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Impossible d'ajouter l'événement au calendrier"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Helper method to create product-specific notifications from alerts
  static Future<void> processAlertForNotification(Alert alert) async {
    switch (alert.typeAlerte) {
      case AlertType.stockFaible:
        final productInfo = _extractProductInfoFromMessage(alert.message);
        await showLowStockNotification(
          id: alert.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          productName: productInfo['name'] ?? 'Produit',
          remainingQuantity: productInfo['quantity'] ?? 0,
          category: productInfo['category'] ?? 'Inconnu',
        );
        break;

      case AlertType.expirationProche:
        final expiryInfo = _extractExpiryInfoFromMessage(alert.message);
        await showExpiryNotification(
          id: alert.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          productName: expiryInfo['name'] ?? 'Produit',
          expiryDate: expiryInfo['date'] ?? 'Bientôt',
          category: expiryInfo['category'] ?? 'Inconnu',
        );
        break;

      case AlertType.reminder:
        await showReminderNotification(
          id: alert.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          reminderTitle: alert.titre,
          message: alert.message,
        );
        break;

      case AlertType.system:
        await showReminderNotification(
          id: alert.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          reminderTitle: alert.titre,
          message: alert.message,
        );
        break;
    }
  }

  static Map<String, dynamic> _extractProductInfoFromMessage(String message) {
    // Simple extraction - in production, you'd use more sophisticated parsing
    // This is a basic implementation for demo purposes

    String productName = '';
    int quantity = 0;
    String category = 'Inconnu';

    // Look for patterns like "Savon est en rupture de stock (quantité restante: 1)"
    if (message.contains('quantité restante:')) {
      final nameMatch = RegExp(r'^([^]+?) est en').firstMatch(message);
      if (nameMatch != null) {
        productName = nameMatch.group(1) ?? '';
      }

      final quantityMatch = RegExp(
        r'quantité restante: (\d+)',
      ).firstMatch(message);
      if (quantityMatch != null) {
        quantity = int.tryParse(quantityMatch.group(1) ?? '0') ?? 0;
      }
    }

    return {'name': productName, 'quantity': quantity, 'category': category};
  }

  static Map<String, dynamic> _extractExpiryInfoFromMessage(String message) {
    // Simple extraction for expiry messages
    String productName = '';
    String expiryDate = '';

    if (message.contains('expire bientôt')) {
      final nameMatch = RegExp(r'^([^]+?) expire').firstMatch(message);
      if (nameMatch != null) {
        productName = nameMatch.group(1)?.trim() ?? '';
      }

      final dateMatch = RegExp(r'le ([^)]+)').firstMatch(message);
      if (dateMatch != null) {
        expiryDate = dateMatch.group(1)?.trim() ?? '';
      }
    }

    return {'name': productName, 'date': expiryDate, 'category': 'Inconnu'};
  }
}

/// Extension to NotificationService for budget-specific notifications
extension BudgetNotifications on NotificationService {
  /// Show budget alert with appropriate severity based on alert level
  ///
  /// Displays system notifications for budget alerts with content and colors
  /// determined by the budget category's alert level (warning, alert, critical).
  /// Falls back to in-app banner if notification permissions are denied.
  ///
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  static Future<void> showBudgetAlert({
    required BudgetCategory category,
    required AnalyticsService analytics,
    BuildContext? context,
  }) async {
    final percentage = (category.spendingPercentage * 100).round();
    final remaining = category.remainingBudget;

    String title;
    String body;
    Color color;

    // Determine notification content based on alert level
    switch (category.alertLevel) {
      case BudgetAlertLevel.warning:
        title = '⚠️ Budget ${category.name} à 80%';
        body = 'Il vous reste ${remaining.toStringAsFixed(2)}€ pour ce mois';
        color = const Color(0xFFFFA500); // Orange
        break;
      case BudgetAlertLevel.alert:
        title = '🚨 Budget ${category.name} dépassé';
        body =
            'Vous avez dépensé ${category.spent.toStringAsFixed(2)}€ sur ${category.limit.toStringAsFixed(2)}€';
        color = const Color(0xFFFF4444); // Red
        break;
      case BudgetAlertLevel.critical:
        title = '⛔ Budget ${category.name} largement dépassé';
        body = 'Attention à vos dépenses - Dépassement de $percentage%';
        color = const Color(0xFFCC0000); // Dark red
        break;
      default:
        return; // No notification for normal level
    }

    // Track analytics first (before attempting notification)
    // Requirements: 2.5, 9.5
    await analytics.logEvent('budget_alert_triggered', parameters: {
      'category': category.name,
      'percentage': percentage,
      'alert_level': category.alertLevel.toString(),
      'spent': category.spent,
      'limit': category.limit,
    });

    try {
      // Show system notification
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'budget_alert_channel',
        'Alertes budget',
        channelDescription: 'Notifications pour les dépassements de budget',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: color,
      );

      const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await NotificationService._flutterLocalNotificationsPlugin.show(
        category.id ?? DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        platformChannelSpecifics,
        payload: 'budget_alert_${category.id}',
      );
    } catch (e, stackTrace) {
      // Log notification failures
      // Requirements: 10.6, 2.6
      await ErrorLoggerService.logError(
        component: 'BudgetNotifications',
        operation: 'showBudgetAlert',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'category_name': category.name,
          'alert_level': category.alertLevel.toString(),
          'percentage': percentage,
          'context_message': 'Failed to show budget notification, falling back to in-app banner',
        },
      );
      
      // Fallback to in-app banner if permissions denied or notification fails
      // Requirement: 2.6
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title\n$body'),
            backgroundColor: color,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      debugPrint('[BudgetNotifications] Failed to show notification: $e');
    }
  }
}

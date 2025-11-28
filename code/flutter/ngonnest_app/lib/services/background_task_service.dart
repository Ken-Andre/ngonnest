import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../models/alert.dart';
import '../models/foyer.dart';
import 'alert_generation_service.dart';
import 'database_service.dart';
import 'error_logger_service.dart';
import 'household_service.dart';
import 'notification_service.dart';

// This function will be called in the background by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Ensure Flutter is initialized for plugin usage in background
    WidgetsFlutterBinding.ensureInitialized();

    print('[BackgroundTask] Starting background task execution');

    // Initialize the database and services
    // NOTE: Remove separate database initialization to avoid competing with main app instance
    final dbService = DatabaseService();
    // Initialize AlertGenerationService with the database service
    await AlertGenerationService().initialize(dbService);
    // HouseholdService is static, no need to instantiate: final householdService = HouseholdService();

    // Re-initialize NotificationService for background context
    await NotificationService.initialize();

    Foyer? foyer; // Changed from HouseholdProfile? to Foyer?

    try {
      print('[BackgroundTask] Checking household profile');
      foyer =
          await HouseholdService.getFoyer(); // Changed from getHouseholdProfile() to getFoyer()

      if (foyer != null && foyer.id != null) {
        print('[BackgroundTask] Processing alerts for foyer: ${foyer.id}');
        // Get unread alerts from AlertGenerationService
        final allAlerts = await AlertGenerationService().generateAllAlerts(
          int.parse(foyer.id!),
        );
        
        final List<Alert> unreadAlerts = AlertGenerationService().filterAlerts(
          allAlerts,
          includeRead: false,
          includeResolved: false,
        );

        print('[BackgroundTask] Found ${unreadAlerts.length} unread alerts');

        for (final alert in unreadAlerts) {
          // Process each unread alert and show a local notification
          await NotificationService.processAlertForNotification(alert);
          // Optionally mark the alert as read after showing notification
          await AlertGenerationService().markAlertAsRead(alert.id);
          print('[BackgroundTask] Processed alert: ${alert.title}');
        }
      } else {
        print('[BackgroundTask] No valid household profile found');
      }

      print('[BackgroundTask] Background task completed successfully');
      return Future.value(true); // Indicate success
    } catch (e, stackTrace) {
      print('[BackgroundTask.ERROR] Error during background task: $e');
      print('[BackgroundTask.ERROR] StackTrace: $stackTrace');

      // Log the background task error
      try {
        await ErrorLoggerService.logError(
          component: 'BackgroundTask',
          operation: 'callbackDispatcher',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.high,
          metadata: {
            'task_name': taskName,
            'has_household_profile':
                foyer?.id != null, // Changed from householdProfile to foyer
          },
        );
      } catch (logError) {
        print('[BackgroundTask.ERROR] Failed to log error: $logError');
      }

      return Future.value(false); // Indicate failure
    }
    // CRITICAL: Remove database.close() to prevent interfering with main app database instance
    // The DatabaseService handles its own connection management and lifecycle
  });
}
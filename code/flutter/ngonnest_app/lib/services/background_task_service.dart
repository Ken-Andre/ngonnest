import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'notification_service.dart';
import 'database_service.dart';
import 'household_service.dart';
import '../models/alert.dart';
import '../models/household_profile.dart';
import '../db.dart';

// This function will be called in the background by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Ensure Flutter is initialized for plugin usage in background
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize the database and services
    final database = await initDatabase();
    final dbService = DatabaseService();
    // HouseholdService is static, no need to instantiate: final householdService = HouseholdService();

    // Re-initialize NotificationService for background context
    await NotificationService.initialize();

    try {
      final householdProfile =
          await HouseholdService.getHouseholdProfile(); // Corrected: Call static method directly

      if (householdProfile != null && householdProfile.id != null) {
        // Get unread alerts from the database
        final List<Alert> unreadAlerts = await dbService.getAlerts(
          idFoyer: householdProfile.id!,
          unreadOnly: true,
        );

        for (final alert in unreadAlerts) {
          // Process each unread alert and show a local notification
          await NotificationService.processAlertForNotification(alert);
          // Optionally mark the alert as read after showing notification
          await dbService.markAlertAsRead(alert.id!);
        }
      }
    } catch (e) {
      print('Error during background task: $e');
      return Future.value(false); // Indicate failure
    } finally {
      // Close the database connection to prevent leaks
      await database.close();
    }

    return Future.value(true); // Indicate success
  });
}

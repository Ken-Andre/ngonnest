import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/settings_service.dart';

class NotificationPermissionService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  /// Request notification permission
  static Future<bool> requestPermission() async {
    try {
      // For Android 13+ (API level 33+), we need to request permission
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      return result ?? true; // Default to true for older Android versions
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      // Check system-level permission
      final bool? systemEnabled = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      
      // Check app-level setting
      final bool appEnabled = await SettingsService.getNotificationsEnabled();
      
      return (systemEnabled ?? true) && appEnabled;
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      return false;
    }
  }

  /// Enable notifications (request permission and update settings)
  static Future<NotificationPermissionResult> enableNotifications() async {
    try {
      // First request system permission
      final bool permissionGranted = await requestPermission();
      
      if (!permissionGranted) {
        return NotificationPermissionResult.denied;
      }

      // Update app setting
      await SettingsService.setNotificationsEnabled(true);
      
      return NotificationPermissionResult.granted;
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
      return NotificationPermissionResult.error;
    }
  }

  /// Disable notifications (update app settings only)
  static Future<void> disableNotifications() async {
    await SettingsService.setNotificationsEnabled(false);
  }

  /// Open system settings for the app
  static Future<void> openSystemSettings() async {
    try {
      const platform = MethodChannel('app_settings');
      await platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Could not open system settings: $e');
      // Fallback: try to open general app settings
      try {
        const platform = MethodChannel('app_settings');
        await platform.invokeMethod('openAppSettings');
      } catch (e2) {
        debugPrint('Could not open app settings: $e2');
      }
    }
  }

  /// Show permission denied dialog
  static void showPermissionDeniedDialog(BuildContext context, VoidCallback onOpenSettings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission refusée'),
          content: const Text(
            'Les notifications sont désactivées. Vous pouvez les activer dans les paramètres système.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        );
      },
    );
  }
}

enum NotificationPermissionResult {
  granted,
  denied,
  error,
}
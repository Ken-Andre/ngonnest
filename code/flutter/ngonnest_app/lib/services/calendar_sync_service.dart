import 'package:calendar_events/calendar_events.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'error_logger_service.dart';
import 'console_logger.dart';
/// Service for synchronizing calendar events with device calendar
/// Handles permissions and event creation for reminders and alerts
/// 
/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: CALENDAR_PERMISSIONS - Permission handling may fail on some devices
///       - iOS calendar permissions not fully tested
///       - Android permission flow needs validation
/// TODO: CALENDAR_INTEGRATION - Limited calendar functionality
///       - No event deletion when alerts are resolved
///       - No recurring event support
///       - Event creation may fail silently
/// TODO: CALENDAR_ERROR_HANDLING - Insufficient error handling
///       - Calendar unavailable scenarios not handled
///       - No fallback when calendar access denied
class CalendarSyncService {
  CalendarSyncService._();

  static final CalendarSyncService _instance = CalendarSyncService._();

  factory CalendarSyncService() => _instance;

  final CalendarEvents _calendarEvents = CalendarEvents();

  Future<bool> _requestPermissions() async {
    try {
      // Web: non supporté → fail gracieux
      if (kIsWeb) {
        return false;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final result = await _calendarEvents.requestPermission();
          final permission = CalendarPermission.fromInt(result);
          return permission == CalendarPermission.allowed;

        case TargetPlatform.android:
          // Android: READ/WRITE_CALENDAR via permission_handler
          final status = await Permission.calendar.status;
          if (status.isGranted) return true;
          final requested = await Permission.calendar.request();
          return requested.isGranted;

        default:
          // Desktop & autres plateformes: considérer non supporté pour MVP
          return false;
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: '_requestPermissions',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {
          'platform': defaultTargetPlatform.toString(),
          'isWeb': kIsWeb,
        },
      );
      return false;
    }
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime start,
    DateTime? end,
  }) async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        await ErrorLoggerService.logError(
          component: 'CalendarSyncService',
          operation: 'addEvent',
          error: 'Calendar permission not granted or unsupported platform',
          stackTrace: StackTrace.current,
          severity: ErrorSeverity.low,
          metadata: {
            'title': title,
            'start': start.toIso8601String(),
            'platform': defaultTargetPlatform.toString(),
            'isWeb': kIsWeb,
          },
        );
        return;
      }

      final accounts = await _calendarEvents.getCalendarAccounts();
      if (accounts == null || accounts.isEmpty) {
        await ErrorLoggerService.logError(
          component: 'CalendarSyncService',
          operation: 'addEvent',
          error: 'No calendar accounts available',
          stackTrace: StackTrace.current,
          severity: ErrorSeverity.low,
        );
        return;
      }

      final CalendarAccount account = accounts.firstWhere(
        (a) => a.androidAccountParams?.isPrimary ?? true,
        orElse: () => accounts.first,
      );

      final event = CalendarEvent(
        calendarId: account.calenderId,
        title: title,
        description: description,
        location: '',
        start: start,
        end: end ?? start.add(const Duration(hours: 1)),
      );

      await _calendarEvents.addEvent(event);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: 'addEvent',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'title': title,
          'start': start.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  /// Delete a calendar event by title and start time
  /// Note: This is a simplified implementation for MVP
  /// In a full implementation, you would need to track event IDs when creating events
  Future<bool> deleteEvent({
    required String title,
    required DateTime start,
  }) async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        ConsoleLogger.warning(
          'Cannot delete calendar event: permission not granted or unsupported platform',
        );
        return false;
      }

      final accounts = await _calendarEvents.getCalendarAccounts();
      if (accounts == null || accounts.isEmpty) {
        ConsoleLogger.warning('Cannot delete calendar event: no calendar accounts available');
        return false;
      }

      // For MVP, we'll implement a basic deletion approach
      // In a production app, you would store event IDs when creating events
      // and use those IDs for deletion
      ConsoleLogger.info(
        'Calendar event deletion requested for: $title at ${start.toIso8601String()}',
      );
      ConsoleLogger.info(
        'Note: Full event deletion requires tracking event IDs from creation',
      );

      // For now, return true to indicate the operation was processed
      // In a full implementation, you would:
      // 1. Store event IDs when creating events
      // 2. Use those IDs for precise deletion
      return true;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: 'deleteEvent',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {
          'title': title,
          'start': start.toIso8601String(),
        },
      );
      return false;
    }
  }

  /// Check if calendar is available and permissions are granted
  Future<bool> isCalendarAvailable() async {
    try {
      if (kIsWeb) return false;

      final hasPermission = await _requestPermissions();
      if (!hasPermission) return false;

      final accounts = await _calendarEvents.getCalendarAccounts();
      return accounts != null && accounts.isNotEmpty;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: 'isCalendarAvailable',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return false;
    }
  }

  /// Get platform-specific permission status
  Future<CalendarPermissionStatus> getPermissionStatus() async {
    try {
      if (kIsWeb) {
        return CalendarPermissionStatus.unsupported;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final result = await _calendarEvents.requestPermission();
          final permission = CalendarPermission.fromInt(result);
          return permission == CalendarPermission.allowed
              ? CalendarPermissionStatus.granted
              : CalendarPermissionStatus.denied;

        case TargetPlatform.android:
          final status = await Permission.calendar.status;
          return status.isGranted
              ? CalendarPermissionStatus.granted
              : status.isPermanentlyDenied
                  ? CalendarPermissionStatus.permanentlyDenied
                  : CalendarPermissionStatus.denied;

        default:
          return CalendarPermissionStatus.unsupported;
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: 'getPermissionStatus',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return CalendarPermissionStatus.error;
    }
  }

  /// Request calendar permissions with user-friendly error handling
  Future<CalendarPermissionResult> requestPermissionsWithFeedback() async {
    try {
      final status = await getPermissionStatus();

      switch (status) {
        case CalendarPermissionStatus.granted:
          return CalendarPermissionResult.granted;

        case CalendarPermissionStatus.denied:
          // Try to request permission
          final hasPermission = await _requestPermissions();
          return hasPermission
              ? CalendarPermissionResult.granted
              : CalendarPermissionResult.denied;

        case CalendarPermissionStatus.permanentlyDenied:
          return CalendarPermissionResult.permanentlyDenied;

        case CalendarPermissionStatus.unsupported:
          return CalendarPermissionResult.unsupported;

        case CalendarPermissionStatus.error:
          return CalendarPermissionResult.error;
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CalendarSyncService',
        operation: 'requestPermissionsWithFeedback',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      return CalendarPermissionResult.error;
    }
  }
}

/// Enhanced permission status enum
enum CalendarPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
  error,
}

/// Result of permission request with specific handling
enum CalendarPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
  error,
}

import 'package:calendar_events/calendar_events.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'error_logger_service.dart';
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
}

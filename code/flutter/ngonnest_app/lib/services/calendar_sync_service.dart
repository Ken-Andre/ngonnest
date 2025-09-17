import 'package:calendar_events/calendar_events.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
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
    if (kIsWeb) {
          return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _calendarEvents.requestPermission();
      final permission = CalendarPermission.fromInt(result);
      return permission == CalendarPermission.allowed;
    }

    final status = await Permission.calendar.status;
    if (status.isGranted) {
      return true;
    }
    else{
      return (await Permission.calendar.request()).isGranted;
    }  
    // Unsupported platforms (desktop, etc.)
    return false;
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime start,
    DateTime? end,
  }) async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) return;

      final accounts = await _calendarEvents.getCalendarAccounts();
      if (accounts == null || accounts.isEmpty) {
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
    } catch (e) {
      debugPrint('Failed to add calendar event: $e');
      rethrow;
    }
  }
}

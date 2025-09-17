import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Debug helper to test Firebase Analytics setup
class AnalyticsDebugHelper {
  static Future<void> testFirebaseSetup() async {
    print('🔍 [Analytics Debug] Starting Firebase setup test...');

    try {
      // Check if Firebase is initialized
      print('🔍 [Analytics Debug] Checking Firebase initialization...');

      if (Firebase.apps.isEmpty) {
        print('❌ [Analytics Debug] Firebase not initialized!');
        print('   Make sure Firebase.initializeApp() is called in main.dart');
        return;
      } else {
        print('✅ [Analytics Debug] Firebase is initialized');
        print('   App name: ${Firebase.app().name}');
      }

      // Check platform
      print('🔍 [Analytics Debug] Platform: ${Platform.operatingSystem}');

      if (!Platform.isAndroid && !Platform.isIOS) {
        print(
          '⚠️ [Analytics Debug] Firebase Analytics only works on Android/iOS',
        );
        return;
      }

      // Test Firebase Analytics instance
      print('🔍 [Analytics Debug] Testing Firebase Analytics instance...');
      final analytics = FirebaseAnalytics.instance;

      // Test logging a simple event
      print('🔍 [Analytics Debug] Logging test event...');
      await analytics.logEvent(
        name: 'debug_test_event',
        parameters: {
          'test_parameter': 'debug_value',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'platform': Platform.operatingSystem,
        },
      );

      print('✅ [Analytics Debug] Test event logged successfully!');

      // Test setting user property
      print('🔍 [Analytics Debug] Setting test user property...');
      await analytics.setUserProperty(
        name: 'debug_test_property',
        value: 'debug_test_value',
      );

      print('✅ [Analytics Debug] User property set successfully!');

      // Instructions for viewing events
      print('');
      print('📊 [Analytics Debug] To view events in Firebase Console:');
      print(
        '   1. Open Firebase Console: https://console.firebase.google.com/',
      );
      print('   2. Select your project');
      print('   3. Go to Analytics > DebugView');
      print('   4. Make sure debug mode is enabled with:');
      print(
        '      adb shell setprop debug.firebase.analytics.app com.ngonnest.ngonnest_app',
      );
      print('   5. Look for "debug_test_event" in the DebugView');
      print('');
    } catch (e, stackTrace) {
      print('❌ [Analytics Debug] Firebase Analytics test failed!');
      print('   Error: $e');
      if (kDebugMode) {
        print('   Stack trace: $stackTrace');
      }

      // Common error solutions
      print('');
      print('🔧 [Analytics Debug] Common solutions:');
      print('   1. Make sure google-services.json is in android/app/');
      print('   2. Check that Firebase project is configured for Flutter');
      print('   3. Verify package name matches Firebase configuration');
      print('   4. Run: flutter clean && flutter pub get');
      print('   5. Rebuild the app completely');
    }
  }

  static Future<void> logTestEvents() async {
    print('🧪 [Analytics Debug] Logging multiple test events...');

    try {
      final analytics = FirebaseAnalytics.instance;

      // Log various test events
      await analytics.logEvent(name: 'test_app_open');
      await analytics.logEvent(
        name: 'test_screen_view',
        parameters: {'screen_name': 'debug_screen'},
      );
      await analytics.logEvent(
        name: 'test_button_click',
        parameters: {'button_name': 'debug_button'},
      );

      print('✅ [Analytics Debug] Multiple test events logged!');
    } catch (e) {
      print('❌ [Analytics Debug] Failed to log test events: $e');
    }
  }

  static void printFirebaseInfo() {
    print('');
    print('🔥 [Firebase Info] Current Firebase configuration:');

    if (Firebase.apps.isNotEmpty) {
      final app = Firebase.app();
      print('   App Name: ${app.name}');
      print('   Project ID: ${app.options.projectId ?? 'Not set'}');
      print('   App ID: ${app.options.appId ?? 'Not set'}');
    } else {
      print('   ❌ No Firebase apps initialized');
    }

    print('   Platform: ${Platform.operatingSystem}');
    print('   Debug Mode: ${kDebugMode}');
    print('');
  }
}

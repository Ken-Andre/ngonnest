// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/main.dart';
import 'package:ngonnest_app/theme/theme_mode_notifier.dart';
import 'package:ngonnest_app/providers/locale_provider.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/connectivity_service.dart';

void main() {
  testWidgets('NgonNest app smoke test', (WidgetTester tester) async {
    // Setup mock preferences
    SharedPreferences.setMockInitialValues({});
    
    // Initialize providers
    final localeProvider = LocaleProvider();
    await localeProvider.initialize();
    final themeModeNotifier = ThemeModeNotifier(ThemeMode.system);
    
    // Build our app with proper providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeModeNotifier>.value(value: themeModeNotifier),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          Provider<DatabaseService>(create: (context) => DatabaseService()),
          ChangeNotifierProvider<ConnectivityService>(create: (context) => ConnectivityService()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    // Look for the splash screen or main content
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

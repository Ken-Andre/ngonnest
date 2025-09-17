import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ngonnest_app/widgets/connectivity_banner.dart';
import 'package:ngonnest_app/services/connectivity_service.dart';

void main() {
  group('ConnectivityBanner Widget Tests', () {
    testWidgets('should not display when connected and banner is hidden', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        true,
        false,
      ); // connected, don't show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Should not find any banner content when connected normally
      expect(find.text('Vous êtes hors ligne'), findsNothing);
      expect(find.text('De retour en ligne'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(find.byIcon(Icons.wifi), findsNothing);
    });

    testWidgets('should display offline banner when not connected', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Should find offline banner elements
      expect(find.text('Vous êtes hors ligne'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Should not find reconnected elements
      expect(find.text('De retour en ligne'), findsNothing);
      expect(find.byIcon(Icons.wifi), findsNothing);
    });

    testWidgets('should display reconnected banner when reconnected', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        true,
        true,
      ); // reconnected, show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Should find reconnected banner elements
      expect(find.text('De retour en ligne'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);

      // Should not find offline elements
      expect(find.text('Vous êtes hors ligne'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('should use theme colors correctly in light mode', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Find the container with the banner
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;

      // Should use error color from light theme
      expect(decoration.color, equals(ThemeData.light().colorScheme.error));
    });

    testWidgets('should use theme colors correctly in dark mode', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Find the container with the banner
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;

      // Should use error color from dark theme
      expect(decoration.color, equals(ThemeData.dark().colorScheme.error));
    });

    testWidgets('should hide banner when close button is tapped', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Find and tap the close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pump();

      // Banner should be hidden after close
      expect(mockConnectivityService.showBanner, isFalse);
    });

    testWidgets('should always show close button', (WidgetTester tester) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      // Should always find close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should use correct border radius from theme', (
      WidgetTester tester,
    ) async {
      final mockConnectivityService = ConnectivityService();
      mockConnectivityService.setConnectivityForTesting(
        false,
        true,
      ); // offline, show banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: mockConnectivityService,
            child: const Scaffold(body: ConnectivityBanner()),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final BorderRadius borderRadius = decoration.borderRadius as BorderRadius;

      // Should use 16px border radius as specified in task
      expect(borderRadius.topLeft.x, equals(16.0));
      expect(borderRadius.topRight.x, equals(16.0));
      expect(borderRadius.bottomLeft.x, equals(16.0));
      expect(borderRadius.bottomRight.x, equals(16.0));
    });
  });
}

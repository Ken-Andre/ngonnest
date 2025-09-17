import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ngonnest_app/services/connectivity_service.dart';
import 'package:ngonnest_app/widgets/connectivity_banner.dart';
import 'package:ngonnest_app/main.dart';

void main() {
  group('Connectivity Integration Tests', () {
    testWidgets(
      'ConnectivityService should update ConnectivityBanner in real-time',
      (WidgetTester tester) async {
        final connectivityService = ConnectivityService();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<ConnectivityService>.value(
              value: connectivityService,
              child: const Scaffold(body: ConnectivityBanner()),
            ),
          ),
        );

        // Initially, banner should be hidden (normal connected state)
        expect(find.text('Vous êtes hors ligne'), findsNothing);
        expect(find.text('De retour en ligne'), findsNothing);

        // Simulate going offline
        connectivityService.setConnectivityForTesting(false, true);
        await tester.pump();

        // Should show offline banner
        expect(find.text('Vous êtes hors ligne'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);

        // Simulate reconnection
        connectivityService.setConnectivityForTesting(true, true);
        await tester.pump();

        // Should show reconnected banner
        expect(find.text('De retour en ligne'), findsOneWidget);
        expect(find.byIcon(Icons.wifi), findsOneWidget);

        // Hide banner
        connectivityService.setConnectivityForTesting(true, false);
        await tester.pump();

        // Banner should be hidden again
        expect(find.text('Vous êtes hors ligne'), findsNothing);
        expect(find.text('De retour en ligne'), findsNothing);
      },
    );

    testWidgets('AppWithConnectivityOverlay should position banner correctly', (
      WidgetTester tester,
    ) async {
      final connectivityService = ConnectivityService();
      connectivityService.setConnectivityForTesting(
        false,
        true,
      ); // Show offline banner

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: connectivityService,
            child: const AppWithConnectivityOverlay(
              child: Scaffold(body: Center(child: Text('Test Screen'))),
            ),
          ),
        ),
      );

      // Should find both the main content and the overlay banner
      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.text('Vous êtes hors ligne'), findsOneWidget);

      // Banner should be positioned as an overlay (using Stack)
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('Banner should respect safe area padding', (
      WidgetTester tester,
    ) async {
      final connectivityService = ConnectivityService();
      connectivityService.setConnectivityForTesting(false, true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ConnectivityService>.value(
            value: connectivityService,
            child: const AppWithConnectivityOverlay(
              child: Scaffold(body: Center(child: Text('Test Screen'))),
            ),
          ),
        ),
      );

      // Find the Positioned widget that contains the banner
      final positionedFinder = find.byType(Positioned);
      expect(positionedFinder, findsOneWidget);

      final Positioned positioned = tester.widget(positionedFinder);

      // Should have proper positioning with safe area consideration
      expect(positioned.top, isNotNull);
      expect(positioned.left, equals(16.0));
      expect(positioned.right, equals(16.0));
    });
  });
}

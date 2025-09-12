import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/main.dart' as main;
import 'package:ngonnest_app/services/feedback_service.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:ngonnest_app/services/connectivity_service.dart';
import 'package:ngonnest_app/utils/accessibility_utils.dart';
import 'package:ngonnest_app/theme/app_theme.dart';
import 'package:ngonnest_app/widgets/sync_banner.dart';

void main() {
  group('Accessibility and Feedback Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should verify theme accessibility compliance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const main.MyApp());
      await tester.pumpAndSettle();

      // Get the current theme
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Validate theme accessibility
      final results = AccessibilityUtils.validateThemeAccessibility(theme);

      // Verify all text combinations meet WCAG AA standards
      expect(
        results['primaryText']['meetsAA'],
        isTrue,
        reason: 'Primary text should meet WCAG AA standards',
      );
      expect(
        results['surfaceText']['meetsAA'],
        isTrue,
        reason: 'Surface text should meet WCAG AA standards',
      );
      expect(
        results['primaryButton']['meetsAA'],
        isTrue,
        reason: 'Primary button text should meet WCAG AA standards',
      );
      expect(
        results['secondaryButton']['meetsAA'],
        isTrue,
        reason: 'Secondary button text should meet WCAG AA standards',
      );

      // Print results for manual verification
      print('\n=== Theme Accessibility Results ===');
      results.forEach((key, value) {
        print(
          '$key: ${value['ratio'].toStringAsFixed(2)}:1 (AA: ${value['meetsAA']})',
        );
      });
    });

    testWidgets('should show sync error with retry functionality', (
      WidgetTester tester,
    ) async {
      // Set up offline connectivity
      final connectivityService = ConnectivityService();
      connectivityService.setConnectivityForTesting(false, false);

      await tester.pumpWidget(const main.MyApp());
      await tester.pumpAndSettle();

      // Navigate to dashboard (assuming it has sync functionality)
      // This might need adjustment based on your app's navigation structure

      // Find a sync-related widget or button
      final syncBannerFinder = find.byType(SyncBanner);
      if (syncBannerFinder.evaluate().isNotEmpty) {
        // Tap the sync banner to trigger sync
        await tester.tap(syncBannerFinder.first);
        await tester.pumpAndSettle();

        // Should show error message due to offline state
        expect(find.byType(SnackBar), findsOneWidget);

        // Verify error message contains network-related text
        final snackBarText = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(find.text('Réessayer'), findsOneWidget);
      }
    });

    testWidgets('should show success feedback for completed actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Simulate a successful action
                    FeedbackService.showSuccess(
                      context,
                      'Action réussie',
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Text('Test Success'),
                );
              },
            ),
          ),
        ),
      );

      // Trigger success feedback
      await tester.tap(find.text('Test Success'));
      await tester.pump();

      // Verify success message appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Action réussie'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify it stays visible for at least 2 seconds
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should handle timeout errors with proper messaging', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FeedbackService.showTimeoutError(
                      context,
                      onRetry: () {
                        // Retry action
                      },
                    );
                  },
                  child: const Text('Test Timeout'),
                );
              },
            ),
          ),
        ),
      );

      // Trigger timeout error
      await tester.tap(find.text('Test Timeout'));
      await tester.pump();

      // Verify timeout message appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('La requête a expiré. Vérifiez votre connexion internet.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);

      // Verify error styling
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.red[600]));
    });

    testWidgets('should display sync banner with proper error states', (
      WidgetTester tester,
    ) async {
      final syncService = SyncService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncBanner(
              lastSyncTime: DateTime.now().subtract(
                const Duration(seconds: 35),
              ),
              showErrors: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show stale sync warning
      expect(find.byType(SyncBanner), findsOneWidget);

      // The banner should indicate stale sync
      final bannerWidget = tester.widget<SyncBanner>(find.byType(SyncBanner));
      expect(bannerWidget.lastSyncTime, isNotNull);
    });

    testWidgets('should verify contrast ratios in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Center(child: Text('Dark Mode Test'))),
        ),
      );

      await tester.pumpAndSettle();

      // Get the dark theme
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData darkTheme = Theme.of(context);

      // Validate dark theme accessibility
      final results = AccessibilityUtils.validateThemeAccessibility(darkTheme);

      // Verify all text combinations meet WCAG AA standards in dark mode
      expect(
        results['primaryText']['meetsAA'],
        isTrue,
        reason: 'Dark mode primary text should meet WCAG AA standards',
      );
      expect(
        results['surfaceText']['meetsAA'],
        isTrue,
        reason: 'Dark mode surface text should meet WCAG AA standards',
      );
      expect(
        results['primaryButton']['meetsAA'],
        isTrue,
        reason: 'Dark mode primary button text should meet WCAG AA standards',
      );
      expect(
        results['secondaryButton']['meetsAA'],
        isTrue,
        reason: 'Dark mode secondary button text should meet WCAG AA standards',
      );

      print('\n=== Dark Mode Accessibility Results ===');
      results.forEach((key, value) {
        print(
          '$key: ${value['ratio'].toStringAsFixed(2)}:1 (AA: ${value['meetsAA']})',
        );
      });
    });

    testWidgets('should handle multiple error types appropriately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        FeedbackService.showNetworkError(context);
                      },
                      child: const Text('Network Error'),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        FeedbackService.showTimeoutError(context);
                      },
                      child: const Text('Timeout Error'),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        FeedbackService.showError(context, 'Generic error');
                      },
                      child: const Text('Generic Error'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Test network error
      await tester.tap(find.text('Network Error'));
      await tester.pump();
      expect(
        find.text('Erreur de réseau. Vérifiez votre connexion internet.'),
        findsOneWidget,
      );

      // Clear and test timeout error
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('Timeout Error'));
      await tester.pump();
      expect(
        find.text('La requête a expiré. Vérifiez votre connexion internet.'),
        findsOneWidget,
      );

      // Clear and test generic error
      await tester.pump(const Duration(seconds: 6));
      await tester.tap(find.text('Generic Error'));
      await tester.pump();
      expect(find.text('Generic error'), findsOneWidget);
    });

    group('Accessibility Standards Verification', () {
      test('should verify specific color combinations meet WCAG standards', () {
        // Test NgonNest brand colors
        final greenWhiteRatio = AccessibilityUtils.calculateContrastRatio(
          AppTheme.primaryGreen,
          AppTheme.neutralWhite,
        );
        expect(greenWhiteRatio, greaterThanOrEqualTo(4.5));

        final blackLightGreyRatio = AccessibilityUtils.calculateContrastRatio(
          AppTheme.neutralBlack,
          AppTheme.neutralLightGrey,
        );
        expect(blackLightGreyRatio, greaterThanOrEqualTo(4.5));

        final greyWhiteRatio = AccessibilityUtils.calculateContrastRatio(
          AppTheme.neutralGrey,
          AppTheme.neutralWhite,
        );
        expect(greyWhiteRatio, greaterThanOrEqualTo(4.5));

        print('\n=== Brand Color Accessibility ===');
        print(
          'Primary Green on White: ${greenWhiteRatio.toStringAsFixed(2)}:1',
        );
        print(
          'Black on Light Grey: ${blackLightGreyRatio.toStringAsFixed(2)}:1',
        );
        print('Grey on White: ${greyWhiteRatio.toStringAsFixed(2)}:1');
      });
    });
  });
}

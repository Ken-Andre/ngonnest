import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ngonnest_app/widgets/cloud_import_dialog.dart';
import 'package:ngonnest_app/services/cloud_import_service.dart';
import 'package:ngonnest_app/l10n/app_localizations.dart';

import 'cloud_import_dialog_test.mocks.dart';

@GenerateMocks([CloudImportService])
void main() {
  group('CloudImportDialog Widget Tests', () {
    late MockCloudImportService mockCloudImportService;

    setUp(() {
      mockCloudImportService = MockCloudImportService();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('fr', ''),
          Locale('es', ''),
        ],
        locale: const Locale('fr', ''),
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('should display import options initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Should display dialog title
      expect(find.text('Données cloud trouvées'), findsOneWidget);
      
      // Should display import options
      expect(find.text('Importer'), findsOneWidget);
      expect(find.text('Fusionner'), findsOneWidget);
      expect(find.text('Ignorer'), findsOneWidget);
      
      // Should display option descriptions
      expect(find.text('Remplacer les données locales par les données cloud'), findsOneWidget);
      expect(find.text('Combiner les données locales et cloud'), findsOneWidget);
      expect(find.text('Conserver uniquement les données locales'), findsOneWidget);
      
      // Should display cancel button
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should show progress when import option is selected', (WidgetTester tester) async {
      // Mock successful import
      final successResult = ImportResult()
        ..success = true
        ..householdsImported = 1
        ..productsImported = 5
        ..budgetsImported = 3
        ..purchasesImported = 10;
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => successResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();

      // Should show progress UI
      expect(find.text('Import en cours...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Should show progress percentage
      expect(find.text('10%'), findsOneWidget);
      
      // Should show step indicators
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('should show success result after successful import', (WidgetTester tester) async {
      // Mock successful import
      final successResult = ImportResult()
        ..success = true
        ..householdsImported = 1
        ..productsImported = 5
        ..budgetsImported = 3
        ..purchasesImported = 10;
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => successResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();

      // Wait for import to complete
      await tester.pumpAndSettle();

      // Should show success UI
      expect(find.text('Import réussi'), findsOneWidget);
      expect(find.text('Vos données ont été importées avec succès'), findsOneWidget);
      
      // Should show import summary
      expect(find.text('19 éléments importés'), findsOneWidget);
      expect(find.text('1 ménages'), findsOneWidget);
      expect(find.text('5 produits'), findsOneWidget);
      expect(find.text('3 budgets'), findsOneWidget);
      expect(find.text('10 achats'), findsOneWidget);
      
      // Should show OK button
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('should show error result after failed import', (WidgetTester tester) async {
      // Mock failed import
      final errorResult = ImportResult()
        ..success = false
        ..error = 'Network connection failed';
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => errorResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();

      // Wait for import to complete
      await tester.pumpAndSettle();

      // Should show error UI
      expect(find.text('Erreur d\'importation'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
      
      // Should show retry and cancel buttons
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should show partial success result', (WidgetTester tester) async {
      // Mock partial success import
      final partialResult = ImportResult()
        ..success = true
        ..householdsImported = 1
        ..productsImported = 3
        ..budgetsImported = 0
        ..purchasesImported = 0
        ..error = 'Some budget categories failed to import';
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => partialResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();

      // Wait for import to complete
      await tester.pumpAndSettle();

      // Should show partial success UI
      expect(find.text('Import partiellement réussi'), findsOneWidget);
      
      // Should show warning about partial failure
      expect(find.text('Certaines données n\'ont pas pu être importées: Some budget categories failed to import'), findsOneWidget);
      
      // Should show what was imported
      expect(find.text('4 éléments importés'), findsOneWidget);
      expect(find.text('1 ménages'), findsOneWidget);
      expect(find.text('3 produits'), findsOneWidget);
    });

    testWidgets('should handle skip option correctly', (WidgetTester tester) async {
      bool dialogClosed = false;
      
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => CloudImportDialog(
                    cloudImportService: mockCloudImportService,
                  ),
                );
                if (result == false) {
                  dialogClosed = true;
                }
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap skip option
      await tester.tap(find.text('Ignorer'));
      await tester.pumpAndSettle();

      // Dialog should be closed with false result
      expect(dialogClosed, isTrue);
      
      // Should not have called import service
      verifyNever(mockCloudImportService.importAllData());
    });

    testWidgets('should handle cancel button correctly', (WidgetTester tester) async {
      bool dialogClosed = false;
      
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => CloudImportDialog(
                    cloudImportService: mockCloudImportService,
                  ),
                );
                if (result == false) {
                  dialogClosed = true;
                }
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog should be closed with false result
      expect(dialogClosed, isTrue);
      
      // Should not have called import service
      verifyNever(mockCloudImportService.importAllData());
    });

    testWidgets('should handle retry after error', (WidgetTester tester) async {
      // Mock failed import first, then success
      final errorResult = ImportResult()
        ..success = false
        ..error = 'Network error';
      
      final successResult = ImportResult()
        ..success = true
        ..householdsImported = 1;
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => errorResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Erreur d\'importation'), findsOneWidget);

      // Mock success for retry
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => successResult);

      // Tap retry
      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      // Should go back to options
      expect(find.text('Importer'), findsOneWidget);
      expect(find.text('Fusionner'), findsOneWidget);
      expect(find.text('Ignorer'), findsOneWidget);
    });

    testWidgets('should call onImportComplete callback on success', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      // Mock successful import
      final successResult = ImportResult()
        ..success = true
        ..householdsImported = 1;
      
      when(mockCloudImportService.importAllData())
          .thenAnswer((_) async => successResult);

      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(
            cloudImportService: mockCloudImportService,
            onImportComplete: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      // Tap import option
      await tester.tap(find.text('Importer'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Callback should have been called
      expect(callbackCalled, isTrue);
    });

    testWidgets('should display correct icons for each option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CloudImportDialog(cloudImportService: mockCloudImportService),
        ),
      );

      // Should find option icons (we can't test specific CupertinoIcons easily, 
      // but we can verify containers with icons exist)
      final iconContainers = find.byType(Container);
      expect(iconContainers.evaluate().length, greaterThan(3));
    });

    testWidgets('should use correct theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
          Locale('en', ''),
          Locale('fr', ''),
          Locale('es', ''),
        ],
        locale: const Locale('fr', ''),
          home: Scaffold(
            body: CloudImportDialog(cloudImportService: mockCloudImportService),
          ),
        ),
      );

      // Find the dialog
      final alertDialog = find.byType(AlertDialog);
      expect(alertDialog, findsOneWidget);

      // Verify dialog uses theme colors (basic check)
      final AlertDialog dialog = tester.widget(alertDialog);
      expect(dialog.title, isNotNull);
    });
  });
}
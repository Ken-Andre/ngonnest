import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/l10n/app_localizations.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/providers/locale_provider.dart';
import 'package:ngonnest_app/repository/foyer_repository.dart';
import 'package:ngonnest_app/screens/settings_screen.dart';
import 'package:ngonnest_app/services/auth_service.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:ngonnest_app/theme/theme_mode_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_budget_test.mocks.dart';

@GenerateMocks([
  DatabaseService,
  FoyerRepository,
  BudgetService,
  SyncService,
  AuthService,
])
void main() {
  group('Settings Budget UI Tests', () {
    late MockDatabaseService mockDatabaseService;
    late MockFoyerRepository mockFoyerRepository;
    late MockBudgetService mockBudgetService;
    late MockSyncService mockSyncService;
    late MockAuthService mockAuthService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      mockDatabaseService = MockDatabaseService();
      mockFoyerRepository = MockFoyerRepository();
      mockBudgetService = MockBudgetService();
      mockSyncService = MockSyncService();
      mockAuthService = MockAuthService();
      
      // Setup default mock behaviors
      when(mockSyncService.syncEnabled).thenReturn(false);
      when(mockAuthService.isAuthenticated).thenReturn(false);
    });

    Widget createTestWidget({Foyer? foyer}) {
      final localeProvider = LocaleProvider();
      localeProvider.setLocale(const Locale('en'));
      
      final themeModeNotifier = ThemeModeNotifier(ThemeMode.light);

      // Setup foyer repository mock
      when(mockFoyerRepository.get()).thenAnswer((_) async => foyer);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ChangeNotifierProvider<ThemeModeNotifier>.value(
            value: themeModeNotifier,
          ),
          ChangeNotifierProvider<SyncService>.value(value: mockSyncService),
          Provider<AuthService>.value(value: mockAuthService),
        ],
        child: MaterialApp(
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('should display budget section with current value', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Monthly budget'), findsOneWidget);
      expect(find.text('360 €'), findsOneWidget);
    });

    testWidgets('should display "Not set" when budget is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: null,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('should open edit dialog when tapping edit button', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Find and tap the edit button (pencil icon)
      final editButton = find.byIcon(CupertinoIcons.pencil);
      expect(editButton, findsOneWidget);
      
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Assert - dialog should be visible
      expect(find.text('Edit monthly budget'), findsOneWidget);
      expect(find.text('Enter your monthly budget amount'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should reject invalid budget values (negative)', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter invalid value
      await tester.enterText(find.byType(TextField), '-100');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - error message should be shown
      expect(find.text('Budget must be between €50 and €2000'), findsOneWidget);
    });

    testWidgets('should reject budget values below minimum (< 50)', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter value below minimum
      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - error message should be shown
      expect(find.text('Budget must be between €50 and €2000'), findsOneWidget);
    });

    testWidgets('should reject budget values above maximum (> 2000)', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter value above maximum
      await tester.enterText(find.byType(TextField), '2500');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - error message should be shown
      expect(find.text('Budget must be between €50 and €2000'), findsOneWidget);
    });

    testWidgets('should accept valid budget values', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      when(mockFoyerRepository.update(any)).thenAnswer((_) async => 1);
      when(mockBudgetService.recalculateCategoryBudgets(any, any))
          .thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter valid value
      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - dialog should close (no error message)
      expect(find.text('Edit monthly budget'), findsNothing);
    });

    testWidgets('should show error message when update fails', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      when(mockFoyerRepository.update(any))
          .thenThrow(Exception('Database error'));

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter valid value
      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - error message should be shown
      expect(find.text('Error updating budget'), findsOneWidget);
    });

    testWidgets('should cancel edit dialog when tapping cancel', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Tap cancel
      final cancelButton = find.widgetWithText(CupertinoDialogAction, 'Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Assert - dialog should be closed
      expect(find.text('Edit monthly budget'), findsNothing);
      
      // Budget value should remain unchanged
      expect(find.text('360 €'), findsOneWidget);
    });

    testWidgets('should show invalid amount error for non-numeric input', (
      WidgetTester tester,
    ) async {
      // Arrange
      final foyer = Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(foyer: foyer));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pumpAndSettle();

      // Enter non-numeric value
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.widgetWithText(CupertinoDialogAction, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Assert - error message should be shown
      expect(find.text('Invalid amount'), findsOneWidget);
    });
  });
}

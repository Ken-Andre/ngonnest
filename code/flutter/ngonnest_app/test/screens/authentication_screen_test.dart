import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/screens/authentication_screen.dart';
import 'package:ngonnest_app/services/auth_service.dart';
import 'package:ngonnest_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthenticationScreen Widget Tests', () {
    setUp(() async {
      // Initialize Supabase for tests
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    });

    testWidgets('should display unified authentication screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the app title is displayed
      expect(find.text('NgonNest'), findsOneWidget);
      
      // Verify welcome message
      expect(find.text('Bienvenue !'), findsOneWidget);
      
      // Verify unified form elements are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      
      // Verify social login buttons are present
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      
      // Verify divider with "ou"
      expect(find.text('ou'), findsOneWidget);
    });

    testWidgets('should display context message when provided', (WidgetTester tester) async {
      const contextMessage = 'Connectez-vous pour activer la synchronisation';
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(
            contextMessage: contextMessage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify context message is displayed
      expect(find.text(contextMessage), findsOneWidget);
    });

    testWidgets('should display all authentication options in unified view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should see email form elements
      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields

      // Should also see OAuth buttons in the same view
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      
      // Should see the divider
      expect(find.text('ou'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');

      // Find and tap submit button
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('should validate password length', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find password field and enter short password
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, '123');

      // Find and tap submit button
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation error (may appear in multiple places)
      expect(find.text('Mot de passe trop court (min 6 caractères)'), findsAtLeastNWidgets(1));
    });

    testWidgets('should toggle between sign-in and sign-up modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in sign-in mode
      expect(find.widgetWithText(ElevatedButton, 'Se connecter'), findsOneWidget);
      expect(find.text('Pas de compte ? Créer un compte'), findsOneWidget);

      // Tap to switch to sign-up mode
      await tester.ensureVisible(find.text('Pas de compte ? Créer un compte'));
      await tester.tap(find.text('Pas de compte ? Créer un compte'));
      await tester.pump();
      await tester.pump(); // Additional pump to ensure state change

      // Should now be in sign-up mode - check for additional fields
      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('Déjà un compte ? Se connecter'), findsOneWidget);
      
      // The button text should change
      expect(find.byType(TextFormField), findsNWidgets(4)); // Email, password, confirm password, full name
    });

    testWidgets('should show loading state when authenticating', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', ''),
          ],
          home: const AuthenticationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      // Tap submit button
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      
      // Should show loading indicator briefly
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
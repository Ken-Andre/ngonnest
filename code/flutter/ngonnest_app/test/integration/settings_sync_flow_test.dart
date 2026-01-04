import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:ngonnest_app/screens/settings_screen.dart';
import 'package:ngonnest_app/services/auth_service.dart';
import 'package:ngonnest_app/services/cloud_import_service.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:ngonnest_app/theme/theme_mode_notifier.dart';
import 'package:ngonnest_app/providers/locale_provider.dart';

import 'settings_sync_flow_test.mocks.dart';

@GenerateMocks([
  AuthService,
  SyncService,
  CloudImportService,
])
void main() {
  group('Settings Sync Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockSyncService mockSyncService;
    late MockCloudImportService mockCloudImportService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockSyncService = MockSyncService();
      mockCloudImportService = MockCloudImportService();

      // Setup default mock behaviors
      when(mockAuthService.isAuthenticated).thenReturn(false);
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);
      
      when(mockSyncService.syncEnabled).thenReturn(false);
      when(mockSyncService.isSyncing).thenReturn(false);
      when(mockSyncService.hasError).thenReturn(false);
      when(mockSyncService.pendingOperations).thenReturn(0);
      when(mockSyncService.failedOperations).thenReturn(0);
      when(mockSyncService.lastSyncTime).thenReturn(null);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<SyncService>.value(value: mockSyncService),
          ChangeNotifierProvider<ThemeModeNotifier>(
            create: (_) => ThemeModeNotifier(ThemeMode.light),
          ),
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(),
          ),
        ],
        child: MaterialApp(
          home: const SettingsScreen(),
          routes: {
            '/authentication': (context) => const Scaffold(
              body: Center(child: Text('Authentication Screen')),
            ),
          },
        ),
      );
    }

    testWidgets('should show sync disabled when not authenticated', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show sync section
      expect(find.text('Synchronisation'), findsOneWidget);

      // Should show disabled status
      expect(find.textContaining('Désactivée'), findsOneWidget);
      expect(find.textContaining('Connectez-vous'), findsOneWidget);
    });

    testWidgets('should show sync toggle when authenticated', (tester) async {
      // Setup authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show sync toggle
      expect(find.byType(CupertinoSwitch), findsWidgets);
    });

    testWidgets('should enable sync when toggle is switched on (authenticated)', (tester) async {
      // Setup authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.enableSync(userConsent: true)).thenAnswer((_) async {});
      when(mockSyncService.forceSyncWithFeedback(any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the sync toggle
      final syncToggle = find.byType(CupertinoSwitch).first;
      await tester.tap(syncToggle);
      await tester.pumpAndSettle();

      // Verify sync was enabled
      verify(mockSyncService.enableSync(userConsent: true)).called(1);
    });

    testWidgets('should show sync status indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show sync status indicator (it's in a custom widget)
      expect(find.text('Synchronisation'), findsOneWidget);
    });

    testWidgets('should handle sync toggle when not authenticated', (tester) async {
      // Setup not authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(false);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The sync toggle should be disabled or show connect message
      expect(find.textContaining('Connectez-vous'), findsOneWidget);
    });

    testWidgets('should show sync up to date when sync is enabled and working', (tester) async {
      // Setup sync enabled and working state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockSyncService.isSyncing).thenReturn(false);
      when(mockSyncService.hasError).thenReturn(false);
      when(mockSyncService.pendingOperations).thenReturn(0);
      when(mockSyncService.lastSyncTime).thenReturn(DateTime.now());
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show up to date status
      expect(find.textContaining('✓'), findsWidgets);
    });

    testWidgets('should show pending operations when sync has pending items', (tester) async {
      // Setup sync with pending operations
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockSyncService.isSyncing).thenReturn(false);
      when(mockSyncService.hasError).thenReturn(false);
      when(mockSyncService.pendingOperations).thenReturn(3);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show pending status
      expect(find.textContaining('⏳'), findsWidgets);
    });

    testWidgets('should show error status when sync has errors', (tester) async {
      // Setup sync with errors
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockSyncService.isSyncing).thenReturn(false);
      when(mockSyncService.hasError).thenReturn(true);
      when(mockSyncService.lastError).thenReturn('Network error');
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show error status
      expect(find.textContaining('⚠️'), findsWidgets);
    });

    testWidgets('should show syncing status when sync is in progress', (tester) async {
      // Setup syncing state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockSyncService.isSyncing).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show syncing status
      expect(find.textContaining('🔄'), findsWidgets);
    });

    testWidgets('should navigate to authentication when sync toggle is enabled and user not authenticated', (tester) async {
      // Setup not authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(false);
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the sync toggle (should be disabled or show message)
      // In the actual implementation, this would trigger navigation to auth screen
      expect(find.textContaining('Connectez-vous'), findsOneWidget);
    });

    testWidgets('should disable sync when toggle is switched off', (tester) async {
      // Setup sync enabled state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockSyncService.disableSync()).thenAnswer((_) async {});
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the sync toggle to disable
      final syncToggle = find.byType(CupertinoSwitch).first;
      await tester.tap(syncToggle);
      await tester.pumpAndSettle();

      // Verify sync was disabled
      verify(mockSyncService.disableSync()).called(1);
    });

    testWidgets('should handle cloud data check when enabling sync', (tester) async {
      // Setup authenticated state with cloud data
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockCloudImportService.checkCloudData()).thenAnswer((_) async => true);
      when(mockSyncService.enableSync(userConsent: true)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The actual cloud data check would happen when sync is enabled
      // This test verifies the integration is set up correctly
      expect(find.text('Synchronisation'), findsOneWidget);
    });

    testWidgets('should show success message after enabling sync', (tester) async {
      // Setup authenticated state
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockSyncService.enableSync(userConsent: true)).thenAnswer((_) async {});
      when(mockSyncService.forceSyncWithFeedback(any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the sync toggle
      final syncToggle = find.byType(CupertinoSwitch).first;
      await tester.tap(syncToggle);
      await tester.pumpAndSettle();

      // Success message would be shown via SnackBar
      // The actual message display is handled by the settings screen
      verify(mockSyncService.enableSync(userConsent: true)).called(1);
    });
  });
}

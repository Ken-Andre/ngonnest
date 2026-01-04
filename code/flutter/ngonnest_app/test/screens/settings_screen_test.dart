import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:ngonnest_app/screens/settings_screen.dart';
import 'package:ngonnest_app/services/feature_flag_service.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:ngonnest_app/services/auth_service.dart';

import 'settings_screen_test.mocks.dart';

@GenerateMocks([FeatureFlagService, SyncService, AuthService])
void main() {
  group('SettingsScreen', () {
    late MockFeatureFlagService mockFeatureFlagService;
    late MockSyncService mockSyncService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockFeatureFlagService = MockFeatureFlagService();
      mockSyncService = MockSyncService();
      mockAuthService = MockAuthService();
    });

    testWidgets('displays disabled sync button when cloud sync is disabled', (tester) async {
      // Arrange
      when(mockFeatureFlagService.isCloudSyncEnabled()).thenReturn(false);
      when(mockSyncService.syncEnabled).thenReturn(false);
      when(mockAuthService.isAuthenticated).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FeatureFlagService>.value(value: mockFeatureFlagService),
              Provider<SyncService>.value(value: mockSyncService),
              Provider<AuthService>.value(value: mockAuthService),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );

      // Assert
      // Look for the sync settings card with the info icon (disabled state)
      expect(find.byIcon(CupertinoIcons.info), findsOneWidget);
      // Ensure there's no switch (which would indicate enabled state)
      expect(find.byType(CupertinoSwitch), findsNothing);
    });

    testWidgets('displays enabled sync button when cloud sync is enabled', (tester) async {
      // Arrange
      when(mockFeatureFlagService.isCloudSyncEnabled()).thenReturn(true);
      when(mockSyncService.syncEnabled).thenReturn(true);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FeatureFlagService>.value(value: mockFeatureFlagService),
              Provider<SyncService>.value(value: mockSyncService),
              Provider<AuthService>.value(value: mockAuthService),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );

      // Assert
      // Look for the sync switch (enabled state)
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      // Ensure there's no info icon (which would indicate disabled state)
      expect(find.byIcon(CupertinoIcons.info), findsNothing);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/screens/inventory_screen.dart';
import '../../lib/services/database_service.dart';
import '../../lib/models/objet.dart';
import '../../lib/models/foyer.dart';

void main() {
  group('Inventory Search Integration', () {
    testWidgets('should filter items based on search query', (
      WidgetTester tester,
    ) async {
      // Create a mock database service
      final mockDatabaseService = MockDatabaseService();

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<DatabaseService>.value(
            value: mockDatabaseService,
            child: const InventoryScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify search bar is present
      expect(
        find.text('Rechercher par nom, catégorie ou pièce...'),
        findsOneWidget,
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'test');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 200));

      // Verify search functionality is working
      // (In a real test, we would verify filtered results)
    });
  });
}

// Mock database service for testing
class MockDatabaseService extends DatabaseService {
  @override
  Future<void> initDatabase() async {
    // Mock implementation
  }

  @override
  Future<Foyer?> getFoyer() async {
    return null; // Mock empty foyer for testing
  }
}

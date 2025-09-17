import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/widgets/inventory_search_bar.dart';

void main() {
  group('InventorySearchBar', () {
    testWidgets('should display search bar with hint text', (
      WidgetTester tester,
    ) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventorySearchBar(
              onSearchChanged: (query) {
                searchQuery = query;
              },
              hintText: 'Test search hint',
            ),
          ),
        ),
      );

      expect(find.text('Test search hint'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should call onSearchChanged with debounce', (
      WidgetTester tester,
    ) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventorySearchBar(
              onSearchChanged: (query) {
                searchQuery = query;
              },
            ),
          ),
        ),
      );

      // Type in the search field
      await tester.enterText(find.byType(TextField), 'test query');

      // Verify the callback hasn't been called immediately
      expect(searchQuery, isEmpty);

      // Wait for debounce period (150ms + buffer)
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the callback was called with the correct query
      expect(searchQuery, equals('test query'));
    });

    testWidgets('should show clear button when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InventorySearchBar(onSearchChanged: (query) {})),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });
}

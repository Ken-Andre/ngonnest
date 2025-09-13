import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/inventory_filter_panel.dart';

void main() {
  group('InventoryFilterPanel', () {
    testWidgets('should display filter panel with toggle button', (
      WidgetTester tester,
    ) async {
      const filterState = InventoryFilterState();
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryFilterPanel(
              filterState: filterState,
              onFilterChanged: (state) {},
              availableRooms: const ['Cuisine', 'Salon'],
              isExpanded: isExpanded,
              onToggleExpanded: () {
                isExpanded = !isExpanded;
              },
            ),
          ),
        ),
      );

      expect(find.text('Filtres'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should show active filter count when filters are applied', (
      WidgetTester tester,
    ) async {
      const filterState = InventoryFilterState(
        selectedRoom: 'Cuisine',
        expiryFilter: ExpiryFilter.expiringSoon,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryFilterPanel(
              filterState: filterState,
              onFilterChanged: (state) {},
              availableRooms: const ['Cuisine', 'Salon'],
              isExpanded: false,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget); // Active filter count
      expect(find.text('Effacer'), findsOneWidget); // Clear button
    });

    testWidgets('should show filter options when expanded', (
      WidgetTester tester,
    ) async {
      const filterState = InventoryFilterState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryFilterPanel(
              filterState: filterState,
              onFilterChanged: (state) {},
              availableRooms: const ['Cuisine', 'Salon'],
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pièce'), findsOneWidget);
      expect(find.text('Date d\'expiration'), findsOneWidget);
      expect(find.text('Toutes'), findsOneWidget);
      expect(find.text('Cuisine'), findsOneWidget);
      expect(find.text('Salon'), findsOneWidget);
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Expire bientôt'), findsOneWidget);
      expect(find.text('Expirés'), findsOneWidget);
    });

    testWidgets('should call onFilterChanged when room filter is selected', (
      WidgetTester tester,
    ) async {
      const filterState = InventoryFilterState();
      InventoryFilterState? changedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryFilterPanel(
              filterState: filterState,
              onFilterChanged: (state) {
                changedState = state;
              },
              availableRooms: const ['Cuisine', 'Salon'],
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cuisine'));
      await tester.pump();

      expect(changedState?.selectedRoom, equals('Cuisine'));
    });

    testWidgets('should call onFilterChanged when expiry filter is selected', (
      WidgetTester tester,
    ) async {
      const filterState = InventoryFilterState();
      InventoryFilterState? changedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryFilterPanel(
              filterState: filterState,
              onFilterChanged: (state) {
                changedState = state;
              },
              availableRooms: const ['Cuisine', 'Salon'],
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Expire bientôt'));
      await tester.pump();

      expect(changedState?.expiryFilter, equals(ExpiryFilter.expiringSoon));
    });
  });
}

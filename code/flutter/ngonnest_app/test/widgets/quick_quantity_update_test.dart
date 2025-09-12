import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/quick_quantity_update.dart';
import '../../lib/models/objet.dart';

void main() {
  group('QuickQuantityUpdate', () {
    late Objet testConsommable;
    late Objet testDurable;

    setUp(() {
      testConsommable = Objet(
        id: 1,
        idFoyer: 1,
        nom: 'Test Consommable',
        categorie: 'Test',
        type: TypeObjet.consommable,
        quantiteInitiale: 10.0,
        quantiteRestante: 5.0,
        unite: 'kg',
      );

      testDurable = Objet(
        id: 2,
        idFoyer: 1,
        nom: 'Test Durable',
        categorie: 'Test',
        type: TypeObjet.durable,
        quantiteInitiale: 1.0,
        quantiteRestante: 1.0,
        unite: 'pièce',
      );
    });

    testWidgets('should display quantity for consumables', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickQuantityUpdate(
              objet: testConsommable,
              onQuantityChanged: (quantity) async {},
            ),
          ),
        ),
      );

      expect(find.text('5.0 kg'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should not display for durables', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickQuantityUpdate(
              objet: testDurable,
              onQuantityChanged: (quantity) async {},
            ),
          ),
        ),
      );

      expect(find.text('1.0 pièce'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('should enter edit mode when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickQuantityUpdate(
              objet: testConsommable,
              onQuantityChanged: (quantity) async {},
            ),
          ),
        ),
      );

      // Tap to enter edit mode
      await tester.tap(find.text('5.0 kg'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should call onQuantityChanged when quantity is updated', (
      WidgetTester tester,
    ) async {
      double? changedQuantity;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickQuantityUpdate(
              objet: testConsommable,
              onQuantityChanged: (quantity) async {
                changedQuantity = quantity;
              },
            ),
          ),
        ),
      );

      // Tap to enter edit mode
      await tester.tap(find.text('5.0 kg'));
      await tester.pump();

      // Enter new quantity
      await tester.enterText(find.byType(TextField), '8.5');

      // Tap check button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(changedQuantity, equals(8.5));
    });

    testWidgets('should cancel edit mode when close button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickQuantityUpdate(
              objet: testConsommable,
              onQuantityChanged: (quantity) async {},
            ),
          ),
        ),
      );

      // Tap to enter edit mode
      await tester.tap(find.text('5.0 kg'));
      await tester.pump();

      // Enter new quantity
      await tester.enterText(find.byType(TextField), '8.5');

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Should be back to display mode with original quantity
      expect(find.text('5.0 kg'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_inventory/screens/stock_entry_screen.dart';

void main() {
  Future<void> pumpEntryScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StockEntryScreen()),
      ),
    );
  }

  testWidgets('Empty form shows field-level validation errors', (tester) async {
    await pumpEntryScreen(tester);

    await tester.tap(find.text('Save Item'));
    await tester.pump();

    expect(find.text('SKU is required.'), findsOneWidget);
    expect(find.text('Item name is required.'), findsOneWidget);
    expect(find.text('Please select a category.'), findsOneWidget);
    expect(find.text('Quantity is required.'), findsOneWidget);
    expect(find.text('Unit price is required.'), findsOneWidget);
    expect(find.text('Reorder level is required.'), findsOneWidget);
  });

  testWidgets('Invalid SKU format is rejected', (tester) async {
    await pumpEntryScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, 'ABC-99');
    await tester.tap(find.text('Save Item'));
    await tester.pump();

    expect(
      find.text('SKU must follow STK- followed by exactly three digits (e.g. STK-101).'),
      findsOneWidget,
    );
  });
}

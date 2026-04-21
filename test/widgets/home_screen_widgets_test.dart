import 'package:calorie_tracker/widgets/log_entry_tile.dart';
import 'package:calorie_tracker/widgets/macro_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MacroBar shows label and current/goal copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroBar(
            label: 'PROTEIN',
            current: 120,
            goal: 180,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('120 / 180 g'), findsOneWidget);
  });

  testWidgets('LogEntryTile renders delete affordance host content',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LogEntryTile(
            title: 'Greek Yogurt',
            subtitle: 'P 18g · C 8g · F 4g',
            caloriesLabel: '220 cal',
          ),
        ),
      ),
    );

    expect(find.text('Greek Yogurt'), findsOneWidget);
    expect(find.text('220 cal'), findsOneWidget);
  });
}

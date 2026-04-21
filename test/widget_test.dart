import 'package:calorie_tracker/widgets/calorie_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CalorieRing renders remaining calories', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieRing(
            eaten: 1200,
            burned: 200,
            goal: 2000,
            size: 72,
          ),
        ),
      ),
    );

    // remaining = goal - eaten + burned = 2000 - 1200 + 200 = 1000
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('left'), findsOneWidget);
  });
}

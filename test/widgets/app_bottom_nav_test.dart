import 'package:calorie_tracker/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bottom nav renders four destinations and forwards taps',
    (tester) async {
      final tappedIndexes = <int>[];
      var addTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: AppBottomNav(
              currentIndex: 1,
              onTap: tappedIndexes.add,
              onAddPressed: () => addTapCount += 1,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Diary'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Add entry'));
      await tester.pump();

      expect(tappedIndexes, <int>[0, 3]);
      expect(addTapCount, 1);
    },
  );
}

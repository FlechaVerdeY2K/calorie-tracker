import 'package:calorie_tracker/screens/app_shell.dart';
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

  testWidgets(
    'app shell swaps top-level views and opens the add sheet',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            destinations: [
              Text('Home Screen'),
              Text('Diary Screen'),
              Text('History Screen'),
              Text('Profile Screen'),
            ],
            logEntrySheetChild: Text('Log Entry Sheet'),
          ),
        ),
      );

      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Diary Screen'), findsNothing);

      await tester.tap(find.text('Diary'));
      await tester.pumpAndSettle();
      expect(find.text('Diary Screen'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('History Screen'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Screen'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Log Entry Sheet'), findsOneWidget);
    },
  );
}

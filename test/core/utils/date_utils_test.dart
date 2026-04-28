import 'package:calorie_tracker/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils', () {
    test('startOfDay zeroes time components', () {
      final d = AppDateUtils.startOfDay(DateTime(2026, 4, 28, 14, 30));
      expect(d, DateTime(2026, 4, 28));
    });

    test('isSameDay true for same date different times', () {
      expect(
        AppDateUtils.isSameDay(
          DateTime(2026, 4, 28, 8, 0),
          DateTime(2026, 4, 28, 23, 59),
        ),
        isTrue,
      );
    });

    test('isSameDay false for different dates', () {
      expect(
        AppDateUtils.isSameDay(DateTime(2026, 4, 28), DateTime(2026, 4, 29)),
        isFalse,
      );
    });

    test('toIsoDate formats correctly', () {
      expect(AppDateUtils.toIsoDate(DateTime(2026, 4, 5)), '2026-04-05');
    });
  });
}

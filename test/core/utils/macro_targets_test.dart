import 'package:calorie_tracker/core/utils/macro_targets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MacroTargets.fromTarget', () {
    late MacroTargets targets;

    setUp(() {
      targets = MacroTargets.fromTarget(calories: 2000, bodyWeightKg: 75);
    });

    test('protein = 1.8 g/kg bodyweight', () {
      expect(targets.proteinG, closeTo(135, 0.01));
    });

    test('fat = 25% of calories / 9', () {
      expect(targets.fatG, closeTo(55.56, 0.01));
    });

    test('carbs fill the remainder', () {
      expect(targets.carbsG, closeTo(240, 0.01));
    });

    test('calories stored as-is', () {
      expect(targets.calories, 2000);
    });

    test('carbs never negative (very high protein edge case)', () {
      final edge = MacroTargets.fromTarget(calories: 400, bodyWeightKg: 200);
      expect(edge.carbsG, greaterThanOrEqualTo(0));
    });
  });
}

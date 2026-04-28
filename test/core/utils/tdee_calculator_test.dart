import 'package:calorie_tracker/core/constants/activity_multipliers.dart';
import 'package:calorie_tracker/core/utils/tdee_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TdeeCalculator.bmr', () {
    test('male 80 kg 175 cm 25 y = 1773.75', () {
      final result = TdeeCalculator.bmr(
        sex: BiologicalSex.male,
        weightKg: 80,
        heightCm: 175,
        ageYears: 25,
      );
      expect(result, closeTo(1773.75, 0.01));
    });

    test('female 65 kg 165 cm 30 y = 1370.25', () {
      final result = TdeeCalculator.bmr(
        sex: BiologicalSex.female,
        weightKg: 65,
        heightCm: 165,
        ageYears: 30,
      );
      expect(result, closeTo(1370.25, 0.01));
    });
  });

  group('TdeeCalculator.tdee', () {
    test('1773.75 × moderate (1.55) ≈ 2749.31', () {
      final result = TdeeCalculator.tdee(
        bmr: 1773.75,
        activity: ActivityLevel.moderate,
      );
      expect(result, closeTo(2749.31, 0.01));
    });
  });

  group('TdeeCalculator.targetCalories', () {
    test('deficit subtracts 500', () {
      expect(
        TdeeCalculator.targetCalories(tdee: 2500, goal: Goal.deficit),
        2000,
      );
    });

    test('maintain rounds tdee', () {
      expect(
        TdeeCalculator.targetCalories(tdee: 2500.6, goal: Goal.maintain),
        2501,
      );
    });

    test('surplus adds 300', () {
      expect(
        TdeeCalculator.targetCalories(tdee: 2500, goal: Goal.surplus),
        2800,
      );
    });
  });
}

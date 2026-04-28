import '../constants/activity_multipliers.dart';

enum BiologicalSex { male, female }

enum Goal { deficit, maintain, surplus }

class TdeeCalculator {
  static double bmr({
    required BiologicalSex sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    return sex == BiologicalSex.male ? base + 5 : base - 161;
  }

  static double tdee({
    required double bmr,
    required ActivityLevel activity,
  }) =>
      bmr * activity.multiplier;

  static int targetCalories({
    required double tdee,
    required Goal goal,
  }) =>
      switch (goal) {
        Goal.deficit => (tdee - 500).round(),
        Goal.maintain => tdee.round(),
        Goal.surplus => (tdee + 300).round(),
      };
}

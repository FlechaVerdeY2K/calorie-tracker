import '../constants/atwater.dart';

class MacroTargets {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int calories;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.calories,
  });

  factory MacroTargets.fromTarget({
    required int calories,
    required double bodyWeightKg,
  }) {
    final proteinG = bodyWeightKg * 1.8;
    final proteinKcal = proteinG * Atwater.kcalPerGramProtein;

    final fatKcal = calories * 0.25;
    final fatG = fatKcal / Atwater.kcalPerGramFat;

    final carbsKcal = calories - proteinKcal - fatKcal;
    final carbsG =
        (carbsKcal / Atwater.kcalPerGramCarbs).clamp(0.0, double.infinity);

    return MacroTargets(
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      calories: calories,
    );
  }
}

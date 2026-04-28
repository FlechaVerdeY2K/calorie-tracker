class Atwater {
  static const double kcalPerGramProtein = 4;
  static const double kcalPerGramCarbs = 4;
  static const double kcalPerGramFat = 9;

  static double calories({
    required double protein,
    required double carbs,
    required double fat,
  }) =>
      protein * kcalPerGramProtein +
      carbs * kcalPerGramCarbs +
      fat * kcalPerGramFat;
}

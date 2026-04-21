double lbsToKg(double lbs) => lbs * 0.453592;

double kgToLbs(double kg) => kg * 2.20462;

double feetInchesToMeters(int feet, int inches) =>
    (feet * 12 + inches) * 0.0254;

(int feet, int inches) metersToFeetInches(double meters) {
  final totalInches = (meters / 0.0254).round();
  return (totalInches ~/ 12, totalInches % 12);
}

double roundKilograms(double value) => double.parse(value.toStringAsFixed(1));

double roundMeters(double value) => double.parse(value.toStringAsFixed(2));

int roundPounds(double value) => value.round();

import 'package:calorie_tracker/utils/unit_conversions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lbsToKg and kgToLbs follow spec rounding', () {
    expect(lbsToKg(185), closeTo(83.9145, 0.0001));
    expect(roundKilograms(lbsToKg(185)), 83.9);
    expect(roundPounds(kgToLbs(83.9)), 185);
  });

  test('feet/inches conversions round-trip cleanly', () {
    final meters = feetInchesToMeters(5, 11);
    final (feet, inches) = metersToFeetInches(meters);

    expect(roundMeters(meters), 1.80);
    expect(feet, 5);
    expect(inches, 11);
  });

  test('metersToFeetInches carries over at the exact foot boundary', () {
    final (feet, inches) = metersToFeetInches(1.8288);

    expect(feet, 6);
    expect(inches, 0);
  });
}

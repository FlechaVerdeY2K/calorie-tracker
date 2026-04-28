import 'package:calorie_tracker/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitConverter protein', () {
    test('28g = 4 exchanges (28/7)', () {
      expect(UnitConverter.gramsToProteinExchanges(28), closeTo(4.0, 0.01));
    });

    test('3 exchanges = 21g', () {
      expect(UnitConverter.proteinExchangesToGrams(3), closeTo(21.0, 0.01));
    });
  });

  group('UnitConverter carbs', () {
    test('30g = 2 exchanges (30/15)', () {
      expect(UnitConverter.gramsToCarbExchanges(30), closeTo(2.0, 0.01));
    });

    test('2 exchanges = 30g', () {
      expect(UnitConverter.carbExchangesToGrams(2), closeTo(30.0, 0.01));
    });
  });

  group('UnitConverter fat', () {
    test('10g = 2 exchanges (10/5)', () {
      expect(UnitConverter.gramsToFatExchanges(10), closeTo(2.0, 0.01));
    });

    test('3 exchanges = 15g', () {
      expect(UnitConverter.fatExchangesToGrams(3), closeTo(15.0, 0.01));
    });
  });
}

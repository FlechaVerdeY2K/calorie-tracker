import '../constants/exchanges.dart';

class UnitConverter {
  static double gramsToProteinExchanges(double grams) =>
      ExchangeTable.proteinToExchanges(grams);

  static double gramsToCarbExchanges(double grams) =>
      ExchangeTable.carbsToExchanges(grams);

  static double gramsToFatExchanges(double grams) =>
      ExchangeTable.fatToExchanges(grams);

  static double proteinExchangesToGrams(double exchanges) =>
      exchanges * ExchangeTable.proteinGramsPerExchange;

  static double carbExchangesToGrams(double exchanges) =>
      exchanges * ExchangeTable.carbsGramsPerExchange;

  static double fatExchangesToGrams(double exchanges) =>
      exchanges * ExchangeTable.fatGramsPerExchange;
}

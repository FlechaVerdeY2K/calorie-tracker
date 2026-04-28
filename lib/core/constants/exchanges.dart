class ExchangeTable {
  static const double proteinGramsPerExchange = 7.0;
  static const double carbsGramsPerExchange = 15.0;
  static const double fatGramsPerExchange = 5.0;
  static const double fruitCarbsPerExchange = 15.0;
  static const double dairyCarbsPerExchange = 12.0;
  static const double dairyProteinPerExchange = 8.0;

  static double proteinToExchanges(double grams) =>
      grams / proteinGramsPerExchange;

  static double carbsToExchanges(double grams) =>
      grams / carbsGramsPerExchange;

  static double fatToExchanges(double grams) =>
      grams / fatGramsPerExchange;
}

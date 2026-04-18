enum UnitSystem { metric, imperial }

extension UnitSystemStorage on UnitSystem {
  String get storageValue => switch (this) {
        UnitSystem.metric => 'metric',
        UnitSystem.imperial => 'imperial',
      };

  static UnitSystem fromStorage(String? value) {
    return value == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;
  }
}

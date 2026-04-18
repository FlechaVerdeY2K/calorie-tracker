import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unit_system.dart';

class UnitSystemNotifier extends ChangeNotifier {
  UnitSystem _unitSystem = UnitSystem.metric;

  UnitSystem get unitSystem => _unitSystem;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUnitSystem =
        UnitSystemStorage.fromStorage(prefs.getString('unit_system'));
    if (loadedUnitSystem != _unitSystem) {
      _unitSystem = loadedUnitSystem;
      notifyListeners();
    }
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    if (value == _unitSystem) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('unit_system', value.storageValue);
    if (!saved) {
      return;
    }

    _unitSystem = value;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unit_system.dart';

class UnitSystemNotifier extends ChangeNotifier {
  UnitSystem _unitSystem = UnitSystem.metric;

  UnitSystem get unitSystem => _unitSystem;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _unitSystem = UnitSystemStorage.fromStorage(prefs.getString('unit_system'));
    notifyListeners();
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    _unitSystem = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit_system', value.storageValue);
  }
}

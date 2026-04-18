import 'package:calorie_tracker/models/unit_system.dart';
import 'package:calorie_tracker/state/unit_system_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('UnitSystemNotifier defaults to metric and persists updates', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = UnitSystemNotifier();
    await notifier.load();
    expect(notifier.unitSystem, UnitSystem.metric);

    await notifier.setUnitSystem(UnitSystem.imperial);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unit_system'), 'imperial');
  });
}

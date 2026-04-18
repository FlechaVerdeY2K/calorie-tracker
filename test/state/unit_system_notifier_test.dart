import 'package:calorie_tracker/models/unit_system.dart';
import 'package:calorie_tracker/state/unit_system_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('UnitSystemNotifier load notifies once when persisted value changes',
      () async {
    SharedPreferences.setMockInitialValues({'unit_system': 'imperial'});

    final notifier = UnitSystemNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.load();

    expect(notifier.unitSystem, UnitSystem.imperial);
    expect(notifications, 1);
  });

  test('UnitSystemNotifier load does not notify when value is unchanged',
      () async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});

    final notifier = UnitSystemNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.load();

    expect(notifier.unitSystem, UnitSystem.metric);
    expect(notifications, 0);
  });

  test('UnitSystemNotifier setUnitSystem notifies once on a real change',
      () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = UnitSystemNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.setUnitSystem(UnitSystem.imperial);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.unitSystem, UnitSystem.imperial);
    expect(prefs.getString('unit_system'), 'imperial');
    expect(notifications, 1);
  });

  test('UnitSystemNotifier same-value set is a no-op', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = UnitSystemNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.setUnitSystem(UnitSystem.metric);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.unitSystem, UnitSystem.metric);
    expect(prefs.getString('unit_system'), isNull);
    expect(notifications, 0);
  });
}

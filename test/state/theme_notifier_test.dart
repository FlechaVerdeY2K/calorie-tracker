import 'package:calorie_tracker/state/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThemeNotifier load notifies once when persisted value changes state',
      () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    final notifier = ThemeNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.load();

    expect(notifier.themeMode, ThemeMode.dark);
    expect(notifications, 1);
  });

  test('ThemeNotifier load does not notify when value is unchanged', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});

    final notifier = ThemeNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.load();

    expect(notifier.themeMode, ThemeMode.system);
    expect(notifications, 0);
  });

  test('ThemeNotifier setThemeMode notifies once on a real change', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = ThemeNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.setThemeMode(ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.themeMode, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(notifications, 1);
  });

  test('ThemeNotifier same-value set is a no-op', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = ThemeNotifier();
    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.setThemeMode(ThemeMode.system);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.themeMode, ThemeMode.system);
    expect(prefs.getString('theme_mode'), isNull);
    expect(notifications, 0);
  });
}

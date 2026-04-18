import 'package:calorie_tracker/state/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class _FailingThemePreferencesStore extends SharedPreferencesStorePlatform {
  _FailingThemePreferencesStore(this._data);

  final Map<String, Object> _data;

  @override
  Future<bool> clear() async => true;

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async => true;

  @override
  Future<Map<String, Object>> getAll() async => Map<String, Object>.from(_data);

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async =>
      getAll();

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

void main() {
  setUp(SharedPreferences.resetStatic);
  tearDown(SharedPreferences.resetStatic);

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

  test('ThemeNotifier keeps old value when persistence fails', () async {
    SharedPreferencesStorePlatform.instance =
        _FailingThemePreferencesStore({'flutter.theme_mode': 'dark'});

    final notifier = ThemeNotifier();
    await notifier.load();

    var notifications = 0;
    notifier.addListener(() {
      notifications++;
    });

    await notifier.setThemeMode(ThemeMode.light);

    expect(notifier.themeMode, ThemeMode.dark);
    expect(notifications, 0);
  });
}

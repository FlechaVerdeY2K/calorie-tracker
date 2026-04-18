import 'package:calorie_tracker/state/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThemeNotifier loads and saves theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    final notifier = ThemeNotifier();
    await notifier.load();

    expect(notifier.themeMode, ThemeMode.dark);

    await notifier.setThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}

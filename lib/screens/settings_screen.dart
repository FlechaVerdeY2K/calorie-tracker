import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 12;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', _remindersEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (_remindersEnabled) {
      await NotificationService().scheduleDaily(
        _reminderTime.hour,
        _reminderTime.minute,
        "Don't forget to log your meals today! 🍽️",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set! ✅')),
        );
      }
    } else {
      await NotificationService().cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminders turned off')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Daily Reminders'),
              subtitle: const Text('Get notified to log your meals'),
              value: _remindersEnabled,
              onChanged: (val) => setState(() => _remindersEnabled = val),
            ),
            const Divider(),
            ListTile(
              enabled: _remindersEnabled,
              title: const Text('Reminder Time'),
              trailing: Text(
                _reminderTime.format(context),
                style: const TextStyle(fontSize: 16),
              ),
              onTap: _remindersEnabled ? _pickTime : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePrefs,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:calorie_tracker/screens/dashboard_screen.dart';
import 'package:calorie_tracker/screens/history_screen.dart';
import 'package:calorie_tracker/screens/log_entry_screen.dart';
import 'package:calorie_tracker/screens/profile_screen.dart';
import 'package:calorie_tracker/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  Future<void> _openLogEntrySheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SizedBox(
        height: 720,
        child: LogEntryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const DashboardScreen(),
      const _DiaryPlaceholderScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogEntrySheet,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddPressed: _openLogEntrySheet,
      ),
    );
  }
}

class _DiaryPlaceholderScreen extends StatelessWidget {
  const _DiaryPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diary')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Diary redesign is coming next.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'For now, use the center add button to log a meal or exercise.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

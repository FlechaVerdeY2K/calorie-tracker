import 'package:calorie_tracker/screens/diary_screen.dart';
import 'package:calorie_tracker/screens/history_screen.dart';
import 'package:calorie_tracker/screens/home_screen.dart';
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

  void _goToDiary({DateTime? date}) {
    setState(() => _currentIndex = 1);
  }

  Future<void> _openLogEntrySheet({String mealSlot = 'lunch'}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: LogEntryScreen(initialMealSlot: mealSlot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onViewFullDiary: _goToDiary),
          const DiaryScreen(),
          HistoryScreen(
            onDayTapped: (date) {
              setState(() => _currentIndex = 1);
            },
          ),
          const ProfileScreen(),
        ],
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

import 'package:calorie_tracker/screens/log_entry_screen.dart';
import 'package:calorie_tracker/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.destinations,
    this.logEntrySheetChild,
  });

  final List<Widget>? destinations;
  final Widget? logEntrySheetChild;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinationCount = 4;
  int _currentIndex = 0;

  List<Widget> get _destinations =>
      widget.destinations ?? _buildDefaultDestinations(context);

  Future<void> _openLogEntrySheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: widget.logEntrySheetChild ?? const LogEntryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      _destinations.length == _destinationCount,
      'AppShell expects exactly $_destinationCount destinations.',
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _destinations,
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

  List<Widget> _buildDefaultDestinations(BuildContext context) {
    return const [
      _ShellPlaceholderScreen(
        title: 'Home',
        message:
            'Home redesign lands in a later task. This shell keeps the app structure in place without reusing legacy screen chrome.',
        icon: Icons.home_rounded,
      ),
      _ShellPlaceholderScreen(
        title: 'Diary',
        message:
            'Diary redesign is coming next. Use the center add button to log a meal or exercise for now.',
        icon: Icons.menu_book_rounded,
      ),
      _ShellPlaceholderScreen(
        title: 'History',
        message:
            'History visuals will arrive in a later redesign task. This tab is a temporary shell-owned placeholder.',
        icon: Icons.bar_chart_rounded,
      ),
      _ShellPlaceholderScreen(
        title: 'Profile',
        message:
            'Profile gets its redesigned content in a future task. The shell stays honest and avoids stacking old navigation chrome.',
        icon: Icons.person_rounded,
      ),
    ];
  }
}

class _ShellPlaceholderScreen extends StatelessWidget {
  const _ShellPlaceholderScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 36, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

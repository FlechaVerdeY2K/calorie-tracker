import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            selected: currentIndex == 0,
            onTap: () => onTap(0),
            colorScheme: theme.colorScheme,
          ),
          _NavItem(
            label: 'Diary',
            icon: Icons.menu_book_rounded,
            selected: currentIndex == 1,
            onTap: () => onTap(1),
            colorScheme: theme.colorScheme,
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Add entry',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAddPressed,
                child: const SizedBox(height: 48),
              ),
            ),
          ),
          _NavItem(
            label: 'History',
            icon: Icons.bar_chart_rounded,
            selected: currentIndex == 2,
            onTap: () => onTap(2),
            colorScheme: theme.colorScheme,
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person_rounded,
            selected: currentIndex == 3,
            onTap: () => onTap(3),
            colorScheme: theme.colorScheme,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.62);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? activeColor : inactiveColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? activeColor : inactiveColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

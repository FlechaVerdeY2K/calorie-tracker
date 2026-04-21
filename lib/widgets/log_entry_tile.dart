import 'package:flutter/material.dart';

class LogEntryTile extends StatelessWidget {
  const LogEntryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.caloriesLabel,
    this.backgroundColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String caloriesLabel;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caloriesLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.close_rounded,
              color: Theme.of(context).colorScheme.outline,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

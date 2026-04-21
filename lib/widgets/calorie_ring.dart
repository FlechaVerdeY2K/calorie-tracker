import 'package:flutter/material.dart';

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.eaten,
    required this.burned,
    required this.goal,
    this.size = 72,
  });

  final double eaten;
  final double burned;
  final double goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final remaining = goal - eaten + burned;
    final progress = goal <= 0 ? 0.0 : (eaten / goal).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining.toStringAsFixed(0),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'left',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

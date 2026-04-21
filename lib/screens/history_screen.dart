import 'package:calorie_tracker/models/daily_summary.dart';
import 'package:calorie_tracker/services/auth_service.dart';
import 'package:calorie_tracker/services/calorie_service.dart';
import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.onDayTapped});

  final void Function(DateTime date)? onDayTapped;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green header
        Container(
          width: double.infinity,
          color: AppColors.lightPrimary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History',
                      style: textTheme.headlineMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Last 7 days',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DailySummary>>(
            future: CalorieService().fetchLast7Days(uid),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final days = snap.data!;
              return _HistoryBody(
                  days: days, onDayTapped: onDayTapped);
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.days, this.onDayTapped});

  final List<DailySummary> days;
  final void Function(DateTime date)? onDayTapped;

  double get _avgCalories {
    if (days.isEmpty) return 0;
    return days.fold<double>(0, (s, d) => s + d.eaten) / days.length;
  }

  int get _deficitDays => days.where((d) => d.net < 0).length;

  int get _surplusDays => days.where((d) => d.net > 0).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxY = days
            .map((d) => d.eaten > d.burned ? d.eaten : d.burned)
            .fold<double>(0, (a, b) => a > b ? a : b) +
        300;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // Bar chart
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: List.generate(days.length, (i) {
                final day = days[i];
                final isToday = i == days.length - 1;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: day.eaten,
                      color: AppColors.lightPrimary
                          .withValues(alpha: isToday ? 1.0 : 0.55),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                    BarChartRodData(
                      toY: day.burned,
                      color: AppColors.lightAccent
                          .withValues(alpha: isToday ? 1.0 : 0.55),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          days[idx].weekdayLabel,
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                        color: colorScheme.onSurface.withValues(alpha: 0.07),
                        strokeWidth: 1,
                      )),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            _LegendDot(color: AppColors.lightPrimary, label: 'Eaten'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.lightAccent, label: 'Burned'),
          ],
        ),
        const SizedBox(height: 24),
        // Weekly stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Avg Daily',
                value: '${_avgCalories.toStringAsFixed(0)}',
                unit: 'cal',
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Deficit Days',
                value: _deficitDays.toString(),
                unit: 'days',
                color: AppColors.lightPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Surplus Days',
                value: _surplusDays.toString(),
                unit: 'days',
                color: AppColors.fat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Daily rows
        ...days.reversed.map((day) {
          final isDeficit = day.net <= 0;
          final netColor =
              isDeficit ? AppColors.lightPrimary : AppColors.fat;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onDayTapped != null
                ? () => onDayTapped!(day.date)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullWeekday(day.date),
                            style: textTheme.titleMedium),
                        Text(
                          _formatDate(day.date),
                          style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    day.netLabel,
                    style: textTheme.titleMedium
                        ?.copyWith(color: netColor),
                  ),
                  if (onDayTapped != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.35),
                        size: 20),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _fullWeekday(DateTime d) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return names[d.weekday - 1];
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: textTheme.labelSmall
                  ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Text(value,
              style: textTheme.displayLarge?.copyWith(color: color)),
          Text(unit,
              style: textTheme.labelSmall
                  ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

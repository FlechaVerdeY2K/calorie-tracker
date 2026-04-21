import 'package:calorie_tracker/models/daily_summary.dart';
import 'package:calorie_tracker/services/auth_service.dart';
import 'package:calorie_tracker/services/calorie_service.dart';
import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:calorie_tracker/widgets/calorie_ring.dart';
import 'package:calorie_tracker/widgets/macro_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onViewFullDiary});

  final VoidCallback onViewFullDiary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<DailySummary> _summaryStream;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    final uid = context.read<AuthService>().currentUser!.uid;
    _summaryStream = CalorieService().watchDailySummary(uid, _today);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder<DailySummary>(
      stream: _summaryStream,
      builder: (context, summarySnap) {
        if (summarySnap.hasError) {
          debugPrint('HomeScreen Firestore error: ${summarySnap.error}');
        }
        final today = _today;
        final summary = summarySnap.data ?? DailySummary.empty(today);
        final textTheme = Theme.of(context).textTheme;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightPrimary,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatHeaderDate(summary.date)} · Goal: ${summary.goal.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Good ${_greetingForHour(today.hour)}, ${_displayName(auth)}',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList.list(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CalorieRing(
                            eaten: summary.eaten,
                            burned: summary.burned,
                            goal: summary.goal,
                            size: 68,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remaining ${summary.remaining.toStringAsFixed(0)}',
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'Eaten ${summary.eaten.toStringAsFixed(0)}'),
                                Text(
                                    'Burned ${summary.burned.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MacroBar(
                    label: 'PROTEIN',
                    current: summary.protein,
                    goal: summary.proteinGoal,
                    color: AppColors.protein,
                  ),
                  const SizedBox(height: 12),
                  MacroBar(
                    label: 'CARBS',
                    current: summary.carbs,
                    goal: summary.carbGoal,
                    color: AppColors.lightAccent,
                  ),
                  const SizedBox(height: 12),
                  MacroBar(
                    label: 'FAT',
                    current: summary.fat,
                    goal: summary.fatGoal,
                    color: AppColors.fat,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: widget.onViewFullDiary,
                    child: const Text('View full diary →'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _displayName(AuthService auth) {
    final user = auth.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'there';
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 18) {
      return 'afternoon';
    }
    return 'evening';
  }

  static String _formatHeaderDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

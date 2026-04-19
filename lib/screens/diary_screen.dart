import 'package:calorie_tracker/models/log_entry_record.dart';
import 'package:calorie_tracker/screens/log_entry_screen.dart';
import 'package:calorie_tracker/services/auth_service.dart';
import 'package:calorie_tracker/services/calorie_service.dart';
import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:calorie_tracker/widgets/log_entry_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedDate;
  late final PageController _datePageController;

  static const _stripDays = 7;
  static const int _centerOffset = 500;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = widget.initialDate ??
        DateTime(today.year, today.month, today.day);
    _datePageController = PageController(
      initialPage: _centerOffset,
      viewportFraction: 1 / _stripDays,
    );
  }

  @override
  void dispose() {
    _datePageController.dispose();
    super.dispose();
  }

  DateTime _pageToDate(int page) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return base.add(Duration(days: page - _centerOffset));
  }

  void _goToDate(DateTime date) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final diff = date.difference(base).inDays;
    setState(() => _selectedDate = date);
    _datePageController.animateToPage(
      _centerOffset + diff,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openLogSheet({String mealSlot = 'lunch'}) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uid = context.read<AuthService>().currentUser!.uid;

    return Column(
      children: [
        // Green header
        Container(
          color: AppColors.lightPrimary,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Diary',
                        style: textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today_rounded,
                            color: Colors.white),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) _goToDate(picked);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Date strip
                SizedBox(
                  height: 60,
                  child: PageView.builder(
                    controller: _datePageController,
                    onPageChanged: (page) {
                      final date = _pageToDate(page);
                      if (!date.isAfter(DateTime.now())) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    itemBuilder: (context, page) {
                      final date = _pageToDate(page);
                      final isToday = _isSameDay(
                          date, DateTime.now());
                      final isSelected = _isSameDay(date, _selectedDate);
                      final isFuture = date.isAfter(DateTime.now());

                      return GestureDetector(
                        onTap: isFuture
                            ? null
                            : () => _goToDate(date),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weekdayShort(date),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isFuture
                                        ? Colors.white38
                                        : isSelected
                                            ? AppColors.lightPrimary
                                            : isToday
                                                ? Colors.white
                                                : Colors.white70,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isFuture
                                        ? Colors.white38
                                        : isSelected
                                            ? AppColors.lightPrimary
                                            : Colors.white,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Diary content
        Expanded(
          child: StreamBuilder<List<LogEntryRecord>>(
            stream: CalorieService().watchEntriesForDay(uid, _selectedDate),
            builder: (context, snap) {
              final entries = snap.data ?? [];

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  ..._mealGroups.map((group) => _MealGroup(
                        slot: group,
                        entries: entries
                            .where((e) => !e.isExercise && e.mealSlot == group)
                            .toList(),
                        onAdd: () => _openLogSheet(mealSlot: group),
                        onDelete: (id) => _confirmDelete(context, id),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      )),
                  _MealGroup(
                    slot: 'exercise',
                    entries: entries.where((e) => e.isExercise).toList(),
                    onAdd: () => _openLogSheet(mealSlot: 'exercise'),
                    onDelete: (id) => _confirmDelete(context, id),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    isExercise: true,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This will permanently remove the entry.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('logs').doc(id).delete();
    }
  }

  static const _mealGroups = ['breakfast', 'lunch', 'dinner', 'snack'];

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _weekdayShort(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
}

class _MealGroup extends StatelessWidget {
  const _MealGroup({
    required this.slot,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
    required this.colorScheme,
    required this.textTheme,
    this.isExercise = false,
  });

  final String slot;
  final List<LogEntryRecord> entries;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isExercise;

  double get _totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                slot.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              if (entries.isNotEmpty)
                Text(
                  isExercise
                      ? '\u2212${_totalCalories.toStringAsFixed(0)} cal'
                      : '${_totalCalories.toStringAsFixed(0)} cal',
                  style: textTheme.bodyMedium?.copyWith(
                      color: isExercise
                          ? AppColors.lightPrimary
                          : colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tap Add to log ${slot == 'exercise' ? 'exercise' : slot}',
                style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.45)),
              ),
            )
          else
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete entry?'),
                          content: const Text(
                              'This will permanently remove the entry.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      return confirmed;
                    },
                    onDismissed: (_) => onDelete(e.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white),
                    ),
                    child: LogEntryTile(
                      title: e.name,
                      subtitle:
                          'P ${e.protein.toStringAsFixed(1)}g  '
                          'C ${e.carbs.toStringAsFixed(1)}g  '
                          'F ${e.fat.toStringAsFixed(1)}g',
                      caloriesLabel: isExercise
                          ? '\u2212${e.calories.toStringAsFixed(0)} cal'
                          : '${e.calories.toStringAsFixed(0)} cal',
                      backgroundColor: isExercise
                          ? const Color(0xFFECFDF5)
                          : null,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

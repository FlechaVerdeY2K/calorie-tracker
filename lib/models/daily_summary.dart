import 'package:calorie_tracker/models/log_entry_record.dart';

class DailySummary {
  const DailySummary({
    required this.date,
    required this.goal,
    required this.eaten,
    required this.burned,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.entries,
  });

  final DateTime date;
  final double goal;
  final double eaten;
  final double burned;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final List<LogEntryRecord> entries;

  double get remaining => goal - eaten + burned;
  double get net => eaten - burned;

  String get weekdayLabel =>
      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

  String get netLabel {
    final rounded = net.round();
    if (rounded == 0) return '0';
    return '${rounded < 0 ? '-' : '+'}${rounded.abs()}';
  }

  factory DailySummary.empty(DateTime date) {
    return DailySummary(
      date: date,
      goal: 0,
      eaten: 0,
      burned: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      proteinGoal: 0,
      carbGoal: 0,
      fatGoal: 0,
      entries: const [],
    );
  }

  DailySummary copyWith({
    double? goal,
    double? eaten,
    double? burned,
    double? protein,
    double? carbs,
    double? fat,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    List<LogEntryRecord>? entries,
  }) {
    return DailySummary(
      date: date,
      goal: goal ?? this.goal,
      eaten: eaten ?? this.eaten,
      burned: burned ?? this.burned,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      entries: entries ?? this.entries,
    );
  }
}

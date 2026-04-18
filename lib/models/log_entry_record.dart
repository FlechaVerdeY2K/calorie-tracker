import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntryRecord {
  const LogEntryRecord({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    required this.type,
    required this.mealSlot,
  });

  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final String type;
  final String mealSlot;

  bool get isExercise => type == 'exercise';

  factory LogEntryRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final rawType = (data['type'] as String? ?? 'meal').toLowerCase();
    final timestamp = data['timestamp'];

    return LogEntryRecord(
      id: id,
      name: data['name'] as String? ?? 'Untitled',
      calories: (data['calories'] as num? ?? 0).toDouble(),
      protein: (data['protein'] as num? ?? 0).toDouble(),
      carbs: (data['carbs'] as num? ?? 0).toDouble(),
      fat: (data['fat'] as num? ?? 0).toDouble(),
      loggedAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      type: rawType == 'food' ? 'meal' : rawType,
      mealSlot: (data['mealSlot'] as String? ?? 'lunch').toLowerCase(),
    );
  }
}

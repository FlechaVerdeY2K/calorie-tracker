import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calorie_tracker/models/daily_summary.dart';
import 'package:calorie_tracker/models/log_entry_record.dart';

class CalorieService {
  final _db = FirebaseFirestore.instance;

  Stream<List<LogEntryRecord>> watchEntriesForDay(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('logs')
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => LogEntryRecord.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<Map<String, double>> todayStream(String uid) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('logs')
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .snapshots()
        .map((snap) {
      double eaten = 0;
      double burned = 0;
      double protein = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['type'] == 'meal') {
          eaten += (data['calories'] as num).toDouble();
          protein += (data['protein'] as num? ?? 0).toDouble();
        }
        if (data['type'] == 'exercise') {
          burned += (data['calories'] as num).toDouble();
        }
      }
      return {'eaten': eaten, 'burned': burned, 'protein': protein};
    });
  }

  Stream<DailySummary> watchDailySummary(String uid, DateTime day) {
    return watchEntriesForDay(uid, day).map((entries) {
      final eaten = entries
          .where((entry) => !entry.isExercise)
          .fold<double>(0, (sum, entry) => sum + entry.calories);
      final burned = entries
          .where((entry) => entry.isExercise)
          .fold<double>(0, (sum, entry) => sum + entry.calories);
      final protein = entries
          .where((entry) => !entry.isExercise)
          .fold<double>(0, (sum, entry) => sum + entry.protein);
      final carbs = entries
          .where((entry) => !entry.isExercise)
          .fold<double>(0, (sum, entry) => sum + entry.carbs);
      final fat = entries
          .where((entry) => !entry.isExercise)
          .fold<double>(0, (sum, entry) => sum + entry.fat);

      return DailySummary.empty(day).copyWith(
        goal: 3260,
        eaten: eaten,
        burned: burned,
        protein: protein,
        carbs: carbs,
        fat: fat,
        proteinGoal: 180,
        carbGoal: 325,
        fatGoal: 80,
        entries: entries,
      );
    });
  }

  Future<List<DailySummary>> fetchLast7Days(String uid) async {
    final today = DateTime.now();
    final futures = List.generate(7, (i) {
      final day =
          DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i));
      return watchDailySummary(uid, day).first;
    });
    return Future.wait(futures);
  }

  Future<int> getStreak(String uid) async {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day =
          DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final end = day.add(const Duration(days: 1));
      final snap = await _db
          .collection('logs')
          .where('uid', isEqualTo: uid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(day))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();
      if (snap.docs.isEmpty) break;
      streak++;
    }
    return streak;
  }

  Stream<List<Map<String, dynamic>>> groupFeedStream() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('logs')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .snapshots()
        .map((snap) {
      final Map<String, Map<String, dynamic>> userTotals = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = data['uid'];
        userTotals.putIfAbsent(uid, () => {'email': data['email'], 'net': 0.0});
        if (data['type'] == 'meal') {
          userTotals[uid]!['net'] += (data['calories'] as num).toDouble();
        } else {
          userTotals[uid]!['net'] -= (data['calories'] as num).toDouble();
        }
      }
      return userTotals.values.toList();
    });
  }
}

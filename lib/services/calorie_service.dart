import 'package:cloud_firestore/cloud_firestore.dart';

class CalorieService {
  final _db = FirebaseFirestore.instance;

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
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['type'] == 'meal') eaten += data['calories'];
        if (data['type'] == 'exercise') burned += data['calories'];
      }
      return {'eaten': eaten, 'burned': burned};
    });
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
        userTotals.putIfAbsent(
            uid, () => {'email': data['email'], 'net': 0.0});
        if (data['type'] == 'meal') {
          userTotals[uid]!['net'] += data['calories'];
        } else {
          userTotals[uid]!['net'] -= data['calories'];
        }
      }
      return userTotals.values.toList();
    });
  }
}
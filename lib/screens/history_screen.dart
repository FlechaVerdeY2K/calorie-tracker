import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchLast7Days() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    final List<Map<String, dynamic>> days = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));

      final snap = await FirebaseFirestore.instance
          .collection('logs')
          .where('uid', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: day)
          .where('timestamp', isLessThan: next)
          .get();

      double eaten = 0;
      double burned = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['type'] == 'meal') eaten += data['calories'];
        if (data['type'] == 'exercise') burned += data['calories'];
      }

      days.add({
        'label': _dayLabel(day),
        'eaten': eaten,
        'burned': burned,
        'net': eaten - burned,
      });
    }

    return days;
  }

  String _dayLabel(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('7-Day History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLast7Days(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final days = snapshot.data!;
          final maxY = days
              .map((d) => (d['eaten'] as double))
              .fold(0.0, (a, b) => a > b ? a : b) + 200;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calories Eaten vs Burned',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Legend
                Row(
                  children: [
                    _LegendDot(color: Colors.orange, label: 'Eaten'),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.blue, label: 'Burned'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: List.generate(days.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: days[i]['eaten'],
                              color: Colors.orange,
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: days[i]['burned'],
                              color: Colors.blue,
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              days[value.toInt()]['label'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Daily Net Calories',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final net = days[i]['net'] as double;
                      return ListTile(
                        title: Text(days[i]['label']),
                        trailing: Text(
                          '${net.toStringAsFixed(0)} kcal net',
                          style: TextStyle(
                            color: net <= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
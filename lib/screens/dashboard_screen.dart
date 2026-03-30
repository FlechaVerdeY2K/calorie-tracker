import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/calorie_service.dart';
import 'log_entry_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.signOut),
        ],
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: CalorieService().todayStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final eaten = snapshot.data!['eaten'] ?? 0;
          final burned = snapshot.data!['burned'] ?? 0;
          final net = eaten - burned;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _SummaryCard(
                  label: 'Calories Eaten',
                  value: eaten,
                  color: Colors.orange,
                  icon: Icons.restaurant,
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  label: 'Calories Burned',
                  value: burned,
                  color: Colors.blue,
                  icon: Icons.local_fire_department,
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  label: 'Net Calories',
                  value: net,
                  color: net <= 0 ? Colors.green : Colors.red,
                  icon: net <= 0 ? Icons.thumb_up : Icons.warning,
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Friends Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: CalorieService().groupFeedStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final feed = snap.data!;
                      if (feed.isEmpty) {
                        return const Center(
                          child: Text('No friends logged yet today.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: feed.length,
                        itemBuilder: (context, i) {
                          final entry = feed[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(entry['email'] ?? 'User'),
                            trailing: Text(
                              '${entry['net'].toStringAsFixed(0)} kcal net',
                              style: TextStyle(
                                color: entry['net'] <= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogEntryScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${value.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

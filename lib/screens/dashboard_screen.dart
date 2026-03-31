import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/calorie_service.dart';
import 'log_entry_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'food_database_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<Map<String, double>> _loadProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'bmr': (data['bmr'] ?? 0).toDouble(),
        'recommendedProtein':
            (data['recommendedProtein'] ?? 0).toDouble(),
      };
    }
    return {'bmr': 0, 'recommendedProtein': 0};
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Food Database',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const FoodDatabaseScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _loadProfile(uid),
        builder: (context, profileSnap) {
          final bmr = profileSnap.data?['bmr'] ?? 0;
          final recommendedProtein =
              profileSnap.data?['recommendedProtein'] ?? 0;

          return StreamBuilder<Map<String, double>>(
            stream: CalorieService().todayStream(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final eaten = snapshot.data!['eaten'] ?? 0;
              final burned = snapshot.data!['burned'] ?? 0;
              final protein = snapshot.data!['protein'] ?? 0;
              final net = eaten - burned;
              final totalBudget = bmr + burned;
              final deficit = totalBudget - eaten;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calorie cards
                    _SummaryCard(
                      label: 'Calories Eaten',
                      value: eaten,
                      color: Colors.orange,
                      icon: Icons.restaurant,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      label: 'Calories Burned (Exercise)',
                      value: burned,
                      color: Colors.blue,
                      icon: Icons.local_fire_department,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      label: 'Net Calories',
                      value: net,
                      color: net <= 0 ? Colors.green : Colors.red,
                      icon: net <= 0 ? Icons.thumb_up : Icons.warning,
                    ),

                    // BMR + deficit
                    if (bmr > 0) ...[
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: 'Total Calorie Budget',
                        value: totalBudget,
                        color: Colors.purple,
                        icon: Icons.calculate,
                        subtitle: 'BMR ${bmr.toStringAsFixed(0)} + Exercise',
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: deficit >= 0 ? 'Deficit' : 'Surplus',
                        value: deficit.abs(),
                        color: deficit >= 0 ? Colors.green : Colors.red,
                        icon: deficit >= 0
                            ? Icons.trending_down
                            : Icons.trending_up,
                        subtitle: deficit >= 0
                            ? 'Under your budget 👍'
                            : 'Over your budget ⚠️',
                      ),
                    ],

                    // Protein tracking
                    if (recommendedProtein > 0) ...[
                      const SizedBox(height: 12),
                      _ProteinCard(
                        consumed: protein,
                        recommended: recommendedProtein,
                      ),
                    ],

                    // Friends feed
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Friends Today',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: CalorieService().groupFeedStream(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final feed = snap.data!;
                        if (feed.isEmpty) {
                          return const Text(
                              'No friends logged yet today.',
                              style: TextStyle(color: Colors.grey));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feed.length,
                          itemBuilder: (context, i) {
                            final entry = feed[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person)),
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
                  ],
                ),
              );
            },
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

class _ProteinCard extends StatelessWidget {
  final double consumed;
  final double recommended;

  const _ProteinCard(
      {required this.consumed, required this.recommended});

  @override
  Widget build(BuildContext context) {
    final progress = (consumed / recommended).clamp(0.0, 1.0);
    final missing = (recommended - consumed).clamp(0.0, double.infinity);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Protein',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(
                      '${consumed.toStringAsFixed(1)}g / ${recommended.toStringAsFixed(1)}g',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: progress >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              missing > 0
                  ? '${missing.toStringAsFixed(1)}g more to reach your goal'
                  : '✅ Protein goal reached!',
              style: TextStyle(
                  fontSize: 12,
                  color: missing > 0 ? Colors.grey : Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey)),
                Text('${value.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  bool _saving = false;
  bool _loading = true;

  // Calculated values
  double _bmr = 0;
  double _recommendedProtein = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _weightController.text = data['weight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _gender = data['gender'] ?? 'male';
      _calculate();
    }
    setState(() => _loading = false);
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final age = double.tryParse(_ageController.text) ?? 0;

    if (weight <= 0 || height <= 0 || age <= 0) return;

    // Mifflin-St Jeor BMR formula
    double bmr;
    if (_gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Recommended protein: 1.6g per kg of body weight (standard for active people)
    final protein = weight * 1.6;

    setState(() {
      _bmr = bmr;
      _recommendedProtein = protein;
    });
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = double.tryParse(_ageController.text);

    if (weight == null || height == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .set({
      'weight': weight,
      'height': height,
      'age': age,
      'gender': _gender,
      'bmr': _bmr,
      'recommendedProtein': _recommendedProtein,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved! ✅')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Body Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Gender toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'male',
                    label: Text('Male'),
                    icon: Icon(Icons.male)),
                ButtonSegment(
                    value: 'female',
                    label: Text('Female'),
                    icon: Icon(Icons.female)),
              ],
              selected: {_gender},
              onSelectionChanged: (val) {
                setState(() => _gender = val.first);
                _calculate();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Body Weight',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                suffixText: 'years',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculate(),
            ),

            // Live calculations
            if (_bmr > 0) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Your Numbers',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _StatRow(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                label: 'Basal Metabolism (BMR)',
                value: '${_bmr.toStringAsFixed(0)} kcal/day',
                subtitle: 'Calories burned at rest',
              ),
              const SizedBox(height: 12),
              _StatRow(
                icon: Icons.fitness_center,
                color: Colors.blue,
                label: 'Recommended Protein',
                value: '${_recommendedProtein.toStringAsFixed(1)}g/day',
                subtitle: '1.6g per kg body weight',
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
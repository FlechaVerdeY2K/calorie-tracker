import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _type = 'meal'; // 'meal' or 'exercise'
  bool _saving = false;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final calories = double.tryParse(_caloriesController.text.trim());

    if (name.isEmpty || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('logs').add({
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'calories': calories,
      'type': _type,
      'timestamp': DateTime.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Entry')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Meal vs Exercise toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'meal',
                    label: Text('Meal'),
                    icon: Icon(Icons.restaurant)),
                ButtonSegment(
                    value: 'exercise',
                    label: Text('Exercise'),
                    icon: Icon(Icons.fitness_center)),
              ],
              selected: {_type},
              onSelectionChanged: (val) =>
                  setState(() => _type = val.first),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _type == 'meal' ? 'Meal name' : 'Exercise name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(
                labelText: _type == 'meal'
                    ? 'Calories eaten'
                    : 'Calories burned',
                border: const OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
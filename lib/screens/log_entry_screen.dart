import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_service.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _gramsController = TextEditingController();
  final _foodService = FoodService();

  String _type = 'meal';
  bool _saving = false;
  bool _searching = false;
  List<FoodItem> _searchResults = [];
  FoodItem? _selectedFood; // store selected food to recalculate on gram change

  // Recalculate nutrition based on grams entered
  void _onGramsChanged(String value) {
    if (_selectedFood == null) return;
    final grams = double.tryParse(value);
    if (grams == null || grams <= 0) return;

    final ratio = grams / _selectedFood!.servingSize;
    setState(() {
      _caloriesController.text =
          (_selectedFood!.calories * ratio).toStringAsFixed(0);
      _protein = (_selectedFood!.protein * ratio);
      _carbs = (_selectedFood!.carbs * ratio);
      _fat = (_selectedFood!.fat * ratio);
    });
  }

  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  Future<void> _searchFood() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await _foodService.search(_searchController.text);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectFood(FoodItem item) {
    setState(() {
      _selectedFood = item;
      _nameController.text = item.name;
      _gramsController.text = item.servingSize.toStringAsFixed(0);
      _caloriesController.text = item.calories.toStringAsFixed(0);
      _protein = item.protein;
      _carbs = item.carbs;
      _fat = item.fat;
      _searchResults = [];
      _searchController.clear();
    });
  }

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
      'protein': _protein,
      'carbs': _carbs,
      'fat': _fat,
      'grams': double.tryParse(_gramsController.text) ?? 0,
      'type': _type,
      'timestamp': DateTime.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
              onSelectionChanged: (val) => setState(() {
                _type = val.first;
                _selectedFood = null;
                _searchResults = [];
                _nameController.clear();
                _caloriesController.clear();
                _gramsController.clear();
                _protein = 0;
                _carbs = 0;
                _fat = 0;
              }),
            ),
            const SizedBox(height: 24),

            // Food search (meals only)
            if (_type == 'meal') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search food...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _searchFood(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searching ? null : _searchFood,
                    child: _searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Search'),
                  ),
                ],
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, i) {
                      final item = _searchResults[i];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                            '${item.servingSize.toStringAsFixed(0)}g serving'),
                        trailing: Text(
                          '${item.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                        onTap: () => _selectFood(item),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _type == 'meal' ? 'Meal name' : 'Exercise name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Grams field (meals only)
            if (_type == 'meal') ...[
              TextField(
                controller: _gramsController,
                decoration: const InputDecoration(
                  labelText: 'Amount eaten',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
                onChanged: _onGramsChanged,
              ),
              const SizedBox(height: 16),
            ],

            // Calories field
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(
                labelText:
                    _type == 'meal' ? 'Calories eaten' : 'Calories burned',
                border: const OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
            ),

            // Macros display (meals only)
            if (_type == 'meal' && _selectedFood != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Macros',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MacroChip(
                            label: 'Protein',
                            value: _protein,
                            color: Colors.blue),
                        _MacroChip(
                            label: 'Carbs',
                            value: _carbs,
                            color: Colors.orange),
                        _MacroChip(
                            label: 'Fat',
                            value: _fat,
                            color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],

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

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
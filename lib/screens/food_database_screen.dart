import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_service.dart';

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final _searchController = TextEditingController();
  final _foodService = FoodService();
  List<FoodItem> _searchResults = [];
  bool _searching = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _searchFood() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searchResults = [];
    });
    try {
      final results = await _foodService.search(_searchController.text);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _saveFromApi(FoodItem item) async {
    await FirebaseFirestore.instance.collection('food_database').add({
      'uid': _uid,
      'name': item.name,
      'portion': item.servingSize,
      'unit': 'g',
      'protein': item.protein,
      'calories': item.calories,
      'carbs': item.carbs,
      'fat': item.fat,
      'mealType': 'Other',
      'proteinPer100': (item.protein / item.servingSize) * 100,
      'caloriesPer100': (item.calories / item.servingSize) * 100,
      'source': 'api',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} saved to database! ✅')),
      );
    }
  }

  Future<void> _deleteFood(String docId) async {
    await FirebaseFirestore.instance
        .collection('food_database')
        .doc(docId)
        .delete();
  }

  // Manual add controllers
  final _nameController = TextEditingController();
  final _portionController = TextEditingController();
  final _unitController = TextEditingController();
  final _proteinController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _mealType = 'Chicken';

  final List<String> _mealTypes = [
    'Beef', 'Chicken', 'Pork', 'Fish',
    'Dairy', 'Carbs', 'Fats', 'Snack',
    'Supplement', 'Drink', 'Other'
  ];

  void _prefillFromApi(FoodItem item) {
    _nameController.text = item.name;
    _portionController.text = item.servingSize.toStringAsFixed(0);
    _unitController.text = 'g';
    _proteinController.text = item.protein.toStringAsFixed(1);
    _caloriesController.text = item.calories.toStringAsFixed(0);
    _carbsController.text = item.carbs.toStringAsFixed(1);
    _fatController.text = item.fat.toStringAsFixed(1);
    setState(() => _searchResults = []);
    _searchController.clear();
    _showAddFood();
  }

  Future<void> _addFood() async {
    final name = _nameController.text.trim();
    final portion = double.tryParse(_portionController.text);
    final protein = double.tryParse(_proteinController.text);
    final calories = double.tryParse(_caloriesController.text);
    final unit = _unitController.text.trim();

    if (name.isEmpty || portion == null ||
        protein == null || calories == null || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('food_database').add({
      'uid': _uid,
      'name': name,
      'portion': portion,
      'unit': unit,
      'protein': protein,
      'calories': calories,
      'carbs': double.tryParse(_carbsController.text) ?? 0,
      'fat': double.tryParse(_fatController.text) ?? 0,
      'mealType': _mealType,
      'proteinPer100': (protein / portion) * 100,
      'caloriesPer100': (calories / portion) * 100,
      'source': 'manual',
    });

    // Clear fields
    for (final c in [_nameController, _portionController, _unitController,
        _proteinController, _caloriesController, _carbsController,
        _fatController]) {
      c.clear();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food added! ✅')),
      );
    }
  }

  void _showAddFood() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Custom Food',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Food name *',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portionController,
                        decoration: const InputDecoration(
                            labelText: 'Portion *',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                            labelText: 'Unit *',
                            hintText: 'g / ml / unit',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        decoration: const InputDecoration(
                            labelText: 'Protein (g) *',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                            labelText: 'Calories *',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _carbsController,
                        decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fatController,
                        decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder()),
                  items: _mealTypes
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => _mealType = val ?? 'Other'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addFood,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Save Food'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Food Database')),
      body: Column(
        children: [
          // Search bar at top
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search food to add...',
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
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Search'),
                ),
              ],
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, i) {
                  final item = _searchResults[i];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        'P: ${item.protein.toStringAsFixed(1)}g  '
                        'C: ${item.carbs.toStringAsFixed(1)}g  '
                        'F: ${item.fat.toStringAsFixed(1)}g  '
                        '· ${item.servingSize.toStringAsFixed(0)}g'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        // Quick save
                        IconButton(
                          icon: const Icon(Icons.save_alt,
                              color: Colors.green),
                          tooltip: 'Save to database',
                          onPressed: () => _saveFromApi(item),
                        ),
                        // Edit before saving
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue),
                          tooltip: 'Edit then save',
                          onPressed: () => _prefillFromApi(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // My saved foods
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('food_database')
                  .where('uid', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No saved foods yet',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text(
                            'Search above or add manually with the + button',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                // Group by meal type
                final Map<String, List<QueryDocumentSnapshot>> grouped =
                    {};
                for (final doc in docs) {
                  final type =
                      (doc.data() as Map)['mealType'] ?? 'Other';
                  grouped.putIfAbsent(type, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ),
                        ...entry.value.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(data['name']),
                              subtitle: Text(
                                '${data['portion']}${data['unit']}  ·  '
                                'P: ${(data['protein'] as num).toStringAsFixed(1)}g  ·  '
                                '${(data['calories'] as num).toStringAsFixed(0)} kcal',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteFood(doc.id),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFood,
        icon: const Icon(Icons.add),
        label: const Text('Add Manually'),
      ),
    );
  }
}